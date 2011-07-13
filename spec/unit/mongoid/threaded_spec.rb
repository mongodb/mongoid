require "spec_helper"

describe Mongoid::Threaded do

  let(:object) do
    stub
  end

  describe "#identity_map" do

    before do
      Thread.current[:"[mongoid]:identity-map"] = object
    end

    after do
      Thread.current[:"[mongoid]:identity-map"] = nil
    end

    it "returns the object with the identity map key" do
      described_class.identity_map.should eq(object)
    end
  end

  describe "#insert" do

    before do
      Thread.current[:"[mongoid]:insert-consumer"] = object
    end

    after do
      Thread.current[:"[mongoid]:insert-consumer"] = nil
    end

    it "returns the object with the insert key" do
      described_class.insert.should eq(object)
    end
  end

  describe "#scope_stack" do

    it "returns the default with the scope stack key" do
      described_class.scope_stack.should be_a(Hash)
    end
  end

  describe "#update" do

    before do
      Thread.current[:"[mongoid]:update-consumer"] = object
    end

    after do
      Thread.current[:"[mongoid]:update-consumer"] = nil
    end

    it "returns the object with the update key" do
      described_class.update.should eq(object)
    end
  end
end
