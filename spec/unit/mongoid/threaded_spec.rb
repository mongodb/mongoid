require "spec_helper"

describe Mongoid::Threaded do

  let(:object) do
    stub
  end

  describe "#binding?" do

    context "when binding is not set" do

      it "returns false" do
        described_class.should_not be_binding
      end
    end

    context "when binding is true" do

      before do
        Thread.current[:"[mongoid]:binding-mode"] = true
      end

      after do
        Thread.current[:"[mongoid]:binding-mode"] = nil
      end

      it "returns true" do
        described_class.should be_binding
      end
    end

    context "when binding is false" do

      before do
        Thread.current[:"[mongoid]:binding-mode"] = false
      end

      after do
        Thread.current[:"[mongoid]:binding-mode"] = nil
      end

      it "returns false" do
        described_class.should_not be_binding
      end
    end
  end

  describe "#binding=" do

    before do
      described_class.binding = true
    end

    after do
      described_class.binding = false
    end

    it "sets the binding mode" do
      described_class.should be_binding
    end
  end

  describe "#building?" do

    context "when building is not set" do

      it "returns false" do
        described_class.should_not be_building
      end
    end

    context "when building is true" do

      before do
        Thread.current[:"[mongoid]:building-mode"] = true
      end

      after do
        Thread.current[:"[mongoid]:building-mode"] = nil
      end

      it "returns true" do
        described_class.should be_building
      end
    end

    context "when building is false" do

      before do
        Thread.current[:"[mongoid]:building-mode"] = false
      end

      after do
        Thread.current[:"[mongoid]:building-mode"] = nil
      end

      it "returns false" do
        described_class.should_not be_building
      end
    end
  end

  describe "#clear_safety_options!" do

    before do
      described_class.safety_options = { :w => 3 }
      described_class.clear_safety_options!
    end

    it "removes all safety options" do
      described_class.safety_options.should be_nil
    end
  end

  describe "#clear_safety_options!" do

    before do
      described_class.safety_options = { :w => 3 }
      described_class.clear_safety_options!
    end

    it "removes all safety options" do
      described_class.safety_options.should be_nil
    end
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

  describe "#insert=" do

    before do
      described_class.insert = object
    end

    after do
      described_class.insert = nil
    end

    let(:consumer) do
      described_class.insert
    end

    it "sets the insert consumer" do
      consumer.should eq(object)
    end
  end

  describe "#safety_options" do

    before do
      described_class.safety_options = { :w => 3 }
    end

    after do
      described_class.safety_options = nil
    end

    let(:options) do
      described_class.safety_options
    end

    it "sets the safety options" do
      options.should eq({ :w => 3 })
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
