# frozen_string_literal: true
# rubocop:todo all

require 'spec_helper'

describe 'Mongoid::Config.isolation_level' do
  def thread_operation(value)
    Thread.new do
      Mongoid::Threaded.stack(:testing) << value
      yield if block_given?
      Mongoid::Threaded.stack(:testing)
    end.join.value
  end

  def fiber_operation(value)
    Fiber.new do
      Mongoid::Threaded.stack(:testing) << value
      yield if block_given?
      Mongoid::Threaded.stack(:testing)
    end.resume
  end

  context 'when set to an unsupported value' do
    it 'raises an error' do
      old_value = Mongoid::Config.isolation_level
      expect { Mongoid::Config.isolation_level = :unsupported }
        .to raise_error(Mongoid::Errors::UnsupportedIsolationLevel)
      expect(Mongoid::Config.isolation_level).to eq(old_value)
    end
  end

  context 'when using older Ruby' do
    ruby_version_lt '3.2'

    context 'when set to :fiber' do
      it 'raises an error' do
        expect { Mongoid::Config.isolation_level = :fiber }
          .to raise_error(Mongoid::Errors::UnsupportedIsolationLevel)
      end
    end

    context 'when set to :thread' do
      around do |example|
        save = Mongoid::Config.isolation_level
        example.run
      ensure
        Mongoid::Config.isolation_level = save
      end

      it 'sets the isolation level' do
        expect { Mongoid::Config.isolation_level = :thread }
          .not_to raise_error
        expect(Mongoid::Config.isolation_level).to eq(:thread)
      end
    end
  end

  context 'when set to :thread' do
    config_override :isolation_level, :thread

    context 'when not operating inside fibers' do
      let(:result1) { thread_operation('a') { thread_operation('b') } }
      let(:result2) { thread_operation('b') { thread_operation('c') } }

      it 'isolates state per thread' do
        expect(result1).to eq(%w[ a ])
        expect(result2).to eq(%w[ b ])
      end
    end

    context 'when operating inside fibers' do
      let(:result) { thread_operation('a') { fiber_operation('b') } }

      it 'exposes the thread state within the fiber' do
        expect(result).to eq(%w[ a b ])
      end
    end
  end

  context 'when using Ruby 3.2+' do
    ruby_version_gte '3.2'

    context 'when set to :fiber' do
      config_override :isolation_level, :fiber

      context 'when operating inside threads' do
        let(:result) { fiber_operation('a') { thread_operation('b') } }

        it 'exposes the fiber state within the thread' do
          expect(result).to eq(%w[ a b ])
        end
      end

      context 'when operating in nested fibers' do
        let(:result) { fiber_operation('a') { fiber_operation('b') } }

        it 'propagates fiber state to nested fibers' do
          expect(result).to eq(%w[ a b ])
        end
      end

      context 'when operating in adjacent fibers' do
        let(:result1) { fiber_operation('a') { fiber_operation('b') } }
        let(:result2) { fiber_operation('c') { fiber_operation('d') } }

        it 'maintains isolation between adjacent fibers' do
          expect(result1).to eq(%w[ a b ])
          expect(result2).to eq(%w[ c d ])
        end
      end

      describe '#reset!' do
        context 'when operating in nested fibers' do
          let (:result) do
            fiber_operation('a') do
              Mongoid::Threaded.reset!

              # once reset, subsequent nested fibers will each have their own
              # state; they won't touch the reset state here.
              fiber_operation('b')
              fiber_operation('c')

              # If we then add to the stack here, it will be unaffected by
              # the previous fiber operations.
              Mongoid::Threaded.stack(:testing) << 'd'
            end
          end

          it 'clears the fiber state' do
            expect(result).to eq(%w[ d ])
          end
        end
      end
    end
  end
end
