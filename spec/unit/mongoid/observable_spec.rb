require "spec_helper"

describe Mongoid::Observable do

  let(:person) do
    Person.new
  end

  let(:address) do
    Address.new
  end

  describe "#add_observer" do

    it "adds an observer to the observer array" do
      address.add_observer(person)
      address.observers.first.should == person
    end
  end

  describe "#notify_observers" do

    before do
      address.add_observer(person)
    end

    context "when observers exist" do

      it "calls update on each observer with the args" do
        person.expects(:observe).with("Testing")
        address.notify_observers("Testing")
      end
    end

    context "when no observers are set up" do

      before do
        @name = Name.new
      end

      it "does notthing" do
        @name.notify_observers("Testing")
      end
    end
  end
end
