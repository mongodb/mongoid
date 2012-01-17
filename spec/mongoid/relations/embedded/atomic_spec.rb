require "spec_helper"

describe Mongoid::Relations::Embedded::Atomic do

  class Atomic
    include Mongoid::Relations::Embedded::Atomic

    def collection
      []
    end

    def root_class
      Person
    end
  end

  describe "#atomically" do

    context "when performing a $set operation" do

      let(:set) do
        stub
      end

      let(:klass) do
        Atomic.new
      end

      before do
        Mongoid::Relations::Embedded::Atomic::Set.expects(:new).returns(set)
        set.expects(:execute)
      end

      context "when in the block" do

        it "puts the updater on the current thread" do
          klass.send(:atomically, :$set) do
            Mongoid::Threaded.update_consumer(Person).should eq(set)
          end
        end
      end

      context "when the block finishes" do

        it "removes the updater from the current thread" do
          klass.send(:atomically, :$set)
          Mongoid::Threaded.update_consumer(Person).should be_nil
        end
      end
    end
  end
end
