require "spec_helper"

describe Mongoid::Collections::CyclicIterator do

  before do
    @first = stub
    @second = stub
    @third = stub
    @fourth = stub
  end

  let(:array) do
    [ @first, @second, @third, @fourth ]
  end

  describe "#initialize" do

    let(:iterator) do
      Mongoid::Collections::CyclicIterator.new(array)
    end

    it "defaults the counter to -1" do
      iterator.counter.should == -1
    end
  end

  describe "#next" do

    context "when the iterator has just been created" do

      let(:iterator) do
        Mongoid::Collections::CyclicIterator.new(array)
      end

      it "returns the first element" do
        iterator.next.should == @first
      end
    end

    context "when the iterator is in the middle" do

      let(:iterator) do
        Mongoid::Collections::CyclicIterator.new(array)
      end

      before do
        2.times { iterator.next }
      end

      it "returns the next element given the index" do
        iterator.next.should == @third
      end
    end

    context "when the iterator is on the last element" do

      let(:iterator) do
        Mongoid::Collections::CyclicIterator.new(array)
      end

      before do
        4.times { iterator.next }
      end

      it "returns the first element" do
        iterator.next.should == @first
      end

      it "resets the counter" do
        iterator.next
        iterator.counter.should == 0
      end
    end
  end
end
