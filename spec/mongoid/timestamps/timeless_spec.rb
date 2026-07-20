# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Timestamps::Timeless do
  describe '#timeless' do
    before(:all) do
      class Chicken
        include Mongoid::Document
        include Mongoid::Timestamps

        before_save :lay_timeless_egg

        def lay_timeless_egg
          Egg.timeless.create!
        end
      end

      class Egg
        include Mongoid::Document
        include Mongoid::Timestamps
      end
    end

    after(:all) do
      Object.send(:remove_const, :Chicken)
      Object.send(:remove_const, :Egg)
    end

    context 'when timeless is used on one instance and then not used on another instance' do
      let!(:first_instance) do
        egg = Egg.create!
        egg.timeless.save!
        egg
      end

      let!(:second_instance) do
        Egg.create!
      end

      it "second instance's created_at is not nil" do
        expect(second_instance.created_at).not_to be_nil
      end
    end

    context 'when others persist in the scope of the chain' do
      context 'when the root executes normally' do
        let!(:chicken) do
          Chicken.create!
        end

        it 'creates the parent with a timestamp' do
          expect(chicken.created_at).not_to be_nil
        end

        it 'creates the child with no timestamp' do
          expect(Egg.last.created_at).to be_nil
        end
      end

      context 'when the root executes timeless' do
        let!(:chicken) do
          Chicken.timeless.create!
        end

        it 'creates the parent with a timestamp' do
          expect(chicken.created_at).to be_nil
        end

        it 'creates the child with no timestamp' do
          expect(Egg.last.created_at).to be_nil
        end
      end
    end

    context 'when used as a proxy method' do
      context 'when used on the document instance' do
        let(:document) do
          Dokument.new
        end

        before do
          document.timeless.save!
        end

        it 'does not set the created timestamp' do
          expect(document.created_at).to be_nil
        end

        it 'does not set the updated timestamp' do
          expect(document.updated_at).to be_nil
        end

        it 'clears out the timeless option after save' do
          expect(document).not_to be_timeless
        end

        context 'when subsequently persisting' do
          before do
            document.update_attribute(:title, 'Sir')
          end

          it 'sets the updated timestamp' do
            expect(document.updated_at).not_to be_nil
          end
        end
      end

      context 'when used on the class' do
        let!(:document) do
          Dokument.timeless.create!
        end

        it 'does not set the created timestamp' do
          expect(document.created_at).to be_nil
        end

        it 'does not set the updated timestamp' do
          expect(document.updated_at).to be_nil
        end

        it 'clears out the timeless option after save' do
          expect(document).not_to be_timeless
        end

        context 'when subsequently persisting' do
          before do
            document.update_attribute(:title, 'Sir')
          end

          it 'sets the updated timestamp' do
            expect(document.updated_at).not_to be_nil
          end
        end
      end
    end
  end

  describe '#timeless with a block' do
    before(:all) do
      class TimelessOther
        include Mongoid::Document
        include Mongoid::Timestamps
      end
    end

    after(:all) do
      Object.send(:remove_const, :TimelessOther)
    end

    context 'when called on an instance' do
      let(:document) { Dokument.new }

      it 'executes the block and persists the document' do
        document.timeless { document.save! }
        expect(document).to be_persisted
      end

      it 'does not set the created timestamp' do
        document.timeless { document.save! }
        expect(document.created_at).to be_nil
      end

      it 'does not set the updated timestamp' do
        document.timeless { document.save! }
        expect(document.updated_at).to be_nil
      end

      it 'returns the value of the block' do
        expect(document.timeless { 42 }).to eq(42)
      end

      it 'resumes timestamping after the block' do
        document.timeless { document.save! }
        document.update_attribute(:title, 'Sir')
        expect(document.updated_at).not_to be_nil
      end

      it 'is not timeless outside the block' do
        document.timeless { document.save! }
        expect(document).not_to be_timeless
      end

      it 'restores state even when the block raises' do
        expect do
          document.timeless { raise 'boom' }
        end.to raise_error('boom')
        expect(document).not_to be_timeless
      end
    end

    context 'when called on the class' do
      it 'does not set timestamps for documents created in the block' do
        document = Dokument.timeless { Dokument.create! }
        expect(document.created_at).to be_nil
        expect(document.updated_at).to be_nil
      end
    end

    context 'when nested' do
      let(:document) { Dokument.new }

      it 'remains timeless until the outermost block exits' do
        Dokument.timeless do
          Dokument.timeless { document.save! }
          # inner block has exited, but we are still inside the outer block
          expect(document).to be_timeless
        end
        expect(document).not_to be_timeless
        expect(document.created_at).to be_nil
      end
    end

    context 'when other documents are persisted in the block' do
      it 'suppresses timestamps globally on the thread for the block duration' do
        other = nil
        Dokument.timeless { other = TimelessOther.create! }
        expect(other.created_at).to be_nil
      end
    end
  end

  # Regression for MONGOID-5782: saving a parent timeless must not bump the
  # updated_at of embedded children, at any nesting depth, when the
  # associations cascade callbacks.
  describe 'MONGOID-5782 cascaded embedded timestamps' do
    before(:all) do
      class TimelessBaz
        include Mongoid::Document
        include Mongoid::Timestamps

        embedded_in :timeless_bar
        field :val, type: String
      end

      class TimelessBar
        include Mongoid::Document
        include Mongoid::Timestamps

        embedded_in :timeless_foo
        embeds_many :timeless_bazs, cascade_callbacks: true
        field :val, type: String
      end

      class TimelessFoo
        include Mongoid::Document
        include Mongoid::Timestamps

        embeds_many :timeless_bars, cascade_callbacks: true
        field :val, type: String
      end
    end

    after(:all) do
      Object.send(:remove_const, :TimelessBaz)
      Object.send(:remove_const, :TimelessBar)
      Object.send(:remove_const, :TimelessFoo)
    end

    let!(:start_time) { Timecop.freeze(Time.at(Time.now.to_i)) }

    let!(:foo) do
      TimelessFoo.create!(timeless_bars: [ { val: 'a', timeless_bazs: [ { val: 'x' } ] } ])
    end

    let(:bar) { foo.timeless_bars.first }
    let(:baz) { bar.timeless_bazs.first }

    after do
      Timecop.return
    end

    it 'does not bump the embedded child updated_at' do
      original = bar.updated_at
      bar.val = 'b'
      Timecop.freeze(Time.at(Time.now.to_i) + 2)
      foo.timeless { foo.save! }
      # the change was actually persisted (the block ran)...
      expect(foo.reload.timeless_bars.first.val).to eq('b')
      # ...but the timestamp was suppressed.
      expect(bar.updated_at).to eq(original)
    end

    it 'does not bump the nested embedded child updated_at' do
      original = baz.updated_at
      baz.val = 'y'
      Timecop.freeze(Time.at(Time.now.to_i) + 2)
      foo.timeless { foo.save! }
      expect(foo.reload.timeless_bars.first.timeless_bazs.first.val).to eq('y')
      expect(baz.updated_at).to eq(original)
    end

    it 'still preserves the parent updated_at' do
      original = foo.updated_at
      foo.val = 'c'
      Timecop.freeze(Time.at(Time.now.to_i) + 2)
      foo.timeless { foo.save! }
      expect(TimelessFoo.find(foo.id).val).to eq('c')
      expect(foo.updated_at).to eq(original)
    end
  end

  describe 'deprecation of the block-less form' do
    let(:document) { Dokument.new }

    it 'warns when called on an instance without a block' do
      expect(Mongoid.logger).to receive(:warn).with(/timeless/).and_call_original
      document.timeless.save!
    end

    it 'warns when called on the class without a block' do
      expect(Mongoid.logger).to receive(:warn).with(/timeless/).and_call_original
      Dokument.timeless.create!
    end

    it 'does not warn when called with a block' do
      expect(Mongoid.logger).not_to receive(:warn)
      document.timeless { document.save! }
    end

    it 'does not warn from the internal touch: false path' do
      document.save!
      document.title = 'changed'
      expect(Mongoid.logger).not_to receive(:warn).with(/timeless/)
      document.save!(touch: false)
    end
  end
end
