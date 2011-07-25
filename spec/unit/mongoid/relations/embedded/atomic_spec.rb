require "spec_helper"

describe Mongoid::Relations::Embedded::Atomic do

  class Atomic
    include Mongoid::Relations::Embedded::Atomic

    def collection
      []
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
            Mongoid::Threaded.update.should == set
          end
        end
      end

      context "when the block finishes" do

        it "removes the updater from the current thread" do
          klass.send(:atomically, :$set)
          Mongoid::Threaded.update.should be_nil
        end
      end
    end
  end
end
