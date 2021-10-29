# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Attributes::Dynamic do
  shared_examples_for 'dynamic field' do
    let(:raw_attributes) do
      {attr_name => 'foo bar'}
    end

    context 'when reading attributes' do
      context 'an unsaved model' do
        it 'can be read' do
          bar = Bar.new(raw_attributes)
          expect(bar.send(attr_name)).to eq('foo bar')
        end
      end

      context 'saved model' do
        it 'can be read' do
          bar = Bar.new(raw_attributes)
          bar.save!

          bar = Bar.find(bar.id)
          expect(bar.send(attr_name)).to eq('foo bar')
        end
      end

      context 'when attribute is not set' do
        it 'cannot be read' do
          bar = Bar.new
          expect do
            bar.send(attr_name)
          end.to raise_error(NoMethodError)
        end

        context 'reading via read_attribute' do
          it 'returns nil' do
            bar = Bar.new
            expect(bar.read_attribute(:foo)).to be nil
          end
        end

        context 'reading via []' do
          it 'returns nil' do
            bar = Bar.new
            expect(bar[:foo]).to be nil
          end
        end
      end
    end

    context 'when writing attributes via constructor' do
      it 'can be written' do
        bar = Bar.new(raw_attributes)
        bar.save!

        bar = Bar.find(bar.id)
        expect(bar.send(attr_name)).to eq('foo bar')
      end
    end

    context 'when writing attributes via attributes=' do
      it 'can be written' do
        bar = Bar.new
        bar.attributes = raw_attributes
        bar.save!

        bar = Bar.find(bar.id)
        expect(bar.send(attr_name)).to eq('foo bar')
      end
    end

    context 'when writing attributes via write_attribute' do
      it 'can be written' do
        bar = Bar.new
        bar.write_attribute(attr_name, 'foo bar')
        bar.save!

        bar = Bar.find(bar.id)
        expect(bar.send(attr_name)).to eq('foo bar')
      end
    end

    context 'when writing attributes via []=' do
      context 'string key' do
        it 'can be written' do
          bar = Bar.new
          bar[attr_name.to_s] = 'foo bar'
          bar.save!

          bar = Bar.find(bar.id)
          expect(bar.send(attr_name)).to eq('foo bar')
        end
      end

      context 'symbol key' do
        it 'can be written' do
          bar = Bar.new
          bar[attr_name.to_sym] = 'foo bar'
          bar.save!

          bar = Bar.find(bar.id)
          expect(bar.send(attr_name)).to eq('foo bar')
        end
      end
    end

    context 'when writing attributes via #{attribute}=' do
      context 'when attribute is not already set' do
        let(:bar) { Bar.new }

        it 'cannot be written' do
          expect do
            bar.send("#{attr_name}=", 'foo bar')
            bar.save!
          end.to raise_error(NoMethodError)
        end
      end

      context 'when attribute is already set' do
        let(:bar) { Bar.new(attr_name => 'foo bar') }

        it 'can be written' do
          bar.send("#{attr_name}=", 'new foo bar')
          bar.save!

          _bar = Bar.find(bar.id)
          expect(_bar.send(attr_name)).to eq('new foo bar')
        end
      end
    end
  end

  context 'when attribute name is alphanumeric' do
    let(:attr_name) { 'foo' }

    it_behaves_like 'dynamic field'
  end

  context 'when attribute name contains spaces' do
    let(:attr_name) { 'hello world' }

    it_behaves_like 'dynamic field'
  end

  context 'when attribute name contains special characters' do
    let(:attr_name) { 'hello%world' }

    it_behaves_like 'dynamic field'
  end
end
