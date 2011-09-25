require "spec_helper"

describe Mongoid::Threaded do

  let(:object) do
    stub
  end

  describe "#begin_assign" do

    before do
      described_class.begin_assign
    end

    after do
      described_class.assign_stack.clear
    end

    it "adds a boolen to the assign stack" do
      described_class.assign_stack.should eq([ true ])
    end
  end

  describe "#assigning?" do

    context "when assigning is not set" do

      it "returns false" do
        described_class.should_not be_assigning
      end
    end

    context "when assigning has elements" do

      before do
        Thread.current[:"[mongoid]:assign-stack"] = [ true ]
      end

      after do
        Thread.current[:"[mongoid]:assign-stack"] = []
      end

      it "returns true" do
        described_class.should be_assigning
      end
    end

    context "when assigning has no elements" do

      before do
        Thread.current[:"[mongoid]:assign-stack"] = []
      end

      it "returns false" do
        described_class.should_not be_assigning
      end
    end
  end

  describe "#assign_stack" do

    context "when no assign stack has been initialized" do

      let(:assigning) do
        described_class.assign_stack
      end

      it "returns an empty stack" do
        assigning.should eq([])
      end
    end

    context "when a assign stack has been initialized" do

      before do
        Thread.current[:"[mongoid]:assign-stack"] = [ true ]
      end

      let(:assigning) do
        described_class.assign_stack
      end

      after do
        Thread.current[:"[mongoid]:assign-stack"] = []
      end

      it "returns the stack" do
        assigning.should eq([ true ])
      end
    end
  end

  describe "#begin_bind" do

    before do
      described_class.begin_bind
    end

    after do
      described_class.bind_stack.clear
    end

    it "adds a boolen to the bind stack" do
      described_class.bind_stack.should eq([ true ])
    end
  end

  describe "#binding?" do

    context "when binding is not set" do

      it "returns false" do
        described_class.should_not be_binding
      end
    end

    context "when binding has elements" do

      before do
        Thread.current[:"[mongoid]:bind-stack"] = [ true ]
      end

      after do
        Thread.current[:"[mongoid]:bind-stack"] = []
      end

      it "returns true" do
        described_class.should be_binding
      end
    end

    context "when binding has no elements" do

      before do
        Thread.current[:"[mongoid]:bind-stack"] = []
      end

      it "returns false" do
        described_class.should_not be_binding
      end
    end
  end

  describe "#bind_stack" do

    context "when no bind stack has been initialized" do

      let(:binding) do
        described_class.bind_stack
      end

      it "returns an empty stack" do
        binding.should eq([])
      end
    end

    context "when a bind stack has been initialized" do

      before do
        Thread.current[:"[mongoid]:bind-stack"] = [ true ]
      end

      let(:binding) do
        described_class.bind_stack
      end

      after do
        Thread.current[:"[mongoid]:bind-stack"] = []
      end

      it "returns the stack" do
        binding.should eq([ true ])
      end
    end
  end

  describe "#begin_build" do

    before do
      described_class.begin_build
    end

    after do
      described_class.build_stack.clear
    end

    it "adds a boolen to the build stack" do
      described_class.build_stack.should eq([ true ])
    end
  end

  describe "#building?" do

    context "when building is not set" do

      it "returns false" do
        described_class.should_not be_building
      end
    end

    context "when building has elements" do

      before do
        Thread.current[:"[mongoid]:build-stack"] = [ true ]
      end

      after do
        Thread.current[:"[mongoid]:build-stack"] = []
      end

      it "returns true" do
        described_class.should be_building
      end
    end

    context "when building has no elements" do

      before do
        Thread.current[:"[mongoid]:build-stack"] = []
      end

      it "returns false" do
        described_class.should_not be_building
      end
    end
  end

  describe "#build_stack" do

    context "when no build stack has been initialized" do

      let(:building) do
        described_class.build_stack
      end

      it "returns an empty stack" do
        building.should eq([])
      end
    end

    context "when a build stack has been initialized" do

      before do
        Thread.current[:"[mongoid]:build-stack"] = [ true ]
      end

      let(:building) do
        described_class.build_stack
      end

      after do
        Thread.current[:"[mongoid]:build-stack"] = []
      end

      it "returns the stack" do
        building.should eq([ true ])
      end
    end
  end

  describe "#begin_create" do

    before do
      described_class.begin_create
    end

    after do
      described_class.create_stack.clear
    end

    it "adds a boolen to the create stack" do
      described_class.create_stack.should eq([ true ])
    end
  end

  describe "#creating?" do

    context "when creating is not set" do

      it "returns false" do
        described_class.should_not be_creating
      end
    end

    context "when creating has elements" do

      before do
        Thread.current[:"[mongoid]:create-stack"] = [ true ]
      end

      after do
        Thread.current[:"[mongoid]:create-stack"] = []
      end

      it "returns true" do
        described_class.should be_creating
      end
    end

    context "when creating has no elements" do

      before do
        Thread.current[:"[mongoid]:create-stack"] = []
      end

      it "returns false" do
        described_class.should_not be_creating
      end
    end
  end

  describe "#create_stack" do

    context "when no create stack has been initialized" do

      let(:creating) do
        described_class.create_stack
      end

      it "returns an empty stack" do
        creating.should eq([])
      end
    end

    context "when a create stack has been initialized" do

      before do
        Thread.current[:"[mongoid]:create-stack"] = [ true ]
      end

      let(:creating) do
        described_class.create_stack
      end

      after do
        Thread.current[:"[mongoid]:create-stack"] = []
      end

      it "returns the stack" do
        creating.should eq([ true ])
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

  describe "#exit_assign" do

    before do
      described_class.begin_assign
      described_class.exit_assign
    end

    after do
      described_class.assign_stack.clear
    end

    it "adds a boolen to the assign stack" do
      described_class.assign_stack.should be_empty
    end
  end

  describe "#exit_bind" do

    before do
      described_class.begin_bind
      described_class.exit_bind
    end

    after do
      described_class.bind_stack.clear
    end

    it "adds a boolen to the bind stack" do
      described_class.bind_stack.should be_empty
    end
  end

  describe "#exit_build" do

    before do
      described_class.begin_build
      described_class.exit_build
    end

    after do
      described_class.build_stack.clear
    end

    it "adds a boolen to the build stack" do
      described_class.build_stack.should be_empty
    end
  end

  describe "#exit_create" do

    before do
      described_class.begin_create
      described_class.exit_create
    end

    after do
      described_class.create_stack.clear
    end

    it "adds a boolen to the create stack" do
      described_class.create_stack.should be_empty
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

  describe "#update_consumer" do

    before do
      Thread.current[:"[mongoid][Person]:update-consumer"] = object
    end

    after do
      Thread.current[:"[mongoid][Person]:update-consumer"] = nil
    end

    it "returns the object with the update key" do
      described_class.update_consumer(Person).should eq(object)
    end
  end

  describe "#set_update_consumer" do

    before do
      described_class.set_update_consumer(Person, object)
    end

    after do
      Thread.current[:"[mongoid][Person]:update-consumer"] = nil
    end

    it "sets the object with the update key" do
      described_class.update_consumer(Person).should eq(object)
    end
  end

  describe "#timeless" do

    before do
      described_class.timeless = true
    end

    after do
      described_class.timeless = false
    end

    it "returns the timeless value" do
      described_class.timeless.should be_true
    end
  end

  describe "#timestamping?" do

    context "when timeless is not set" do

      it "returns true" do
        described_class.should be_timestamping
      end
    end

    context "when timeless is true" do

      before do
        described_class.timeless = true
      end

      after do
        described_class.timeless = false
      end

      it "returns false" do
        described_class.should_not be_timestamping
      end
    end
  end

  describe "#begin_validate" do

    let(:person) do
      Person.new
    end

    before do
      described_class.begin_validate(person)
    end

    after do
      described_class.exit_validate(person)
    end

    it "marks the document as being validated" do
      described_class.validations_for(Person).should eq([ person.id ])
    end
  end

  describe "#exit_validate" do

    let(:person) do
      Person.new
    end

    before do
      described_class.begin_validate(person)
      described_class.exit_validate(person)
    end

    it "unmarks the document as being validated" do
      described_class.validations_for(Person).should be_empty
    end
  end

  describe "#validated?" do

    let(:person) do
      Person.new
    end

    context "when the document is validated" do

      before do
        described_class.begin_validate(person)
      end

      after do
        described_class.exit_validate(person)
      end

      it "returns true" do
        described_class.validated?(person).should be_true
      end
    end

    context "when the document is not validated" do

      it "returns false" do
        described_class.validated?(person).should be_false
      end
    end
  end
end
