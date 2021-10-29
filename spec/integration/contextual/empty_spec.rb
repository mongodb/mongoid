# frozen_string_literal: true

require 'spec_helper'

describe 'Contextual classes when dealing with empty result set' do
  shared_examples 'behave as expected' do
    context '#exists?' do
      it 'is false' do
        context.exists?.should be false
      end
    end

    context '#count' do
      it 'is 0' do
        context.count.should == 0
      end
    end

    context '#length' do
      it 'is 0' do
        context.length.should == 0
      end
    end

    # #estimated_count only exists for Mongo

    context '#distinct' do
      it 'is empty array' do
        context.distinct(:foo).should == []
      end
    end

    context '#each' do
      context 'with block' do
        it 'does not invoke the block' do
          called = false
          context.each do
            called = true
          end
          called.should be false
        end
      end

      context 'without block' do
        it 'returns Enumerable' do
          context.each.should be_a(Enumerable)
        end

        it 'returns empty Enumerable' do
          context.each.to_a.should == []
        end
      end
    end

    context '#map' do
      context 'with block' do
        it 'does not invoke the block' do
          called = false
          context.map do
            called = true
          end
          called.should be false
        end
      end

      context 'without block' do
        it 'returns empty array' do
          skip 'MONGOID-5148'

          context.map(:field).should == []
        end
      end
    end

    context '#first' do
      it 'is nil' do
        context.first.should be nil
      end
    end

    context '#find_first' do
      it 'is nil' do
        context.find_first.should be nil
      end
    end

    context '#one' do
      it 'is nil' do
        context.one.should be nil
      end
    end

    context '#last' do
      it 'is nil' do
        context.last.should be nil
      end
    end
  end

  let(:context) do
    context_cls.new(criteria)
  end

  before do
    # Create an object of the same class used in the Criteria instance
    # to verify we are using the Contextual classes.
    Mop.create!
  end

  context 'Mongo' do
    let(:context_cls) { Mongoid::Contextual::Mongo }

    let(:criteria) do
      Mop.and(Mop.where(a: 1), Mop.where(a: 2))
    end

    include_examples 'behave as expected'
  end

  context 'Memory' do
    let(:context_cls) { Mongoid::Contextual::Memory }

    let(:criteria) do
      Mop.all.tap do |criteria|
        criteria.documents = []
      end
    end

    include_examples 'behave as expected'
  end

  context 'None' do
    let(:context_cls) { Mongoid::Contextual::None }

    let(:criteria) do
      Mop.none
    end

    include_examples 'behave as expected'
  end
end
