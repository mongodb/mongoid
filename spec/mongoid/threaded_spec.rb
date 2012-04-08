require "spec_helper"

describe Mongoid::Threaded do

  let(:object) do
    stub
  end

  describe "#begin" do

    before do
      described_class.begin(:load)
    end

    after do
      described_class.stack(:load).clear
    end

    it "adds a boolen to the load stack" do
      described_class.stack(:load).should eq([ true ])
    end
  end

  describe "#executing?" do

    context "when loading is not set" do

      it "returns false" do
        described_class.should_not be_executing(:load)
      end
    end

    context "when the stack has elements" do

      before do
        Thread.current[:"[mongoid]:load-stack"] = [ true ]
      end

      after do
        Thread.current[:"[mongoid]:load-stack"] = []
      end

      it "returns true" do
        described_class.should be_executing(:load)
      end
    end

    context "when the stack has no elements" do

      before do
        Thread.current[:"[mongoid]:load-stack"] = []
      end

      it "returns false" do
        described_class.should_not be_executing(:load)
      end
    end
  end

  describe "#stack" do

    context "when no stack has been initialized" do

      let(:loading) do
        described_class.stack(:load)
      end

      it "returns an empty stack" do
        loading.should be_empty
      end
    end

    context "when a stack has been initialized" do

      before do
        Thread.current[:"[mongoid]:load-stack"] = [ true ]
      end

      let(:loading) do
        described_class.stack(:load)
      end

      after do
        Thread.current[:"[mongoid]:load-stack"] = []
      end

      it "returns the stack" do
        loading.should eq([ true ])
      end
    end
  end

  describe "#exit" do

    before do
      described_class.begin(:load)
      described_class.exit(:load)
    end

    after do
      described_class.stack(:load).clear
    end

    it "removes a boolen from the stack" do
      described_class.stack(:load).should be_empty
    end
  end

  describe "#clear_persistence_options" do

    before do
      described_class.set_persistence_options(Band, { safe: { w: 3 }})
    end

    let!(:cleared) do
      described_class.clear_persistence_options(Band)
    end

    it "removes all persistence options" do
      described_class.persistence_options(Band).should be_nil
    end

    it "returns true" do
      cleared.should be_true
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
      Thread.current[:"[mongoid][test]:insert-consumer"] = object
    end

    after do
      Thread.current[:"[mongoid][test]:insert-consumer"] = nil
    end

    it "returns the object with the insert key" do
      described_class.insert("test").should eq(object)
    end
  end

  describe "#set_insert" do

    before do
      described_class.set_insert("test", object)
    end

    after do
      described_class.set_insert("test", nil)
    end

    let(:consumer) do
      described_class.insert("test")
    end

    it "sets the insert consumer" do
      consumer.should eq(object)
    end
  end

  describe "#persistence_options" do

    before do
      described_class.set_persistence_options(Band, { safe: { w: 3 }})
    end

    after do
      described_class.set_persistence_options(Band, nil)
    end

    let(:options) do
      described_class.persistence_options(Band)
    end

    it "sets the persistence options" do
      options.should eq({ safe: { w: 3 }})
    end
  end

  describe "#scope_stack" do

    it "returns the default with the scope stack key" do
      described_class.scope_stack.should be_a(Hash)
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

  describe "#begin_autosave" do

    let(:person) do
      Person.new
    end

    before do
      described_class.begin_autosave(person)
    end

    after do
      described_class.exit_autosave(person)
    end

    it "marks the document as being autosaved" do
      described_class.autosaves_for(Person).should eq([ person.id ])
    end
  end

  describe "#exit_autosave" do

    let(:person) do
      Person.new
    end

    before do
      described_class.begin_autosave(person)
      described_class.exit_autosave(person)
    end

    it "unmarks the document as being autosaved" do
      described_class.autosaves_for(Person).should be_empty
    end
  end

  describe "#autosaved?" do

    let(:person) do
      Person.new
    end

    context "when the document is autosaved" do

      before do
        described_class.begin_autosave(person)
      end

      after do
        described_class.exit_autosave(person)
      end

      it "returns true" do
        described_class.autosaved?(person).should be_true
      end
    end

    context "when the document is not autosaved" do

      it "returns false" do
        described_class.autosaved?(person).should be_false
      end
    end
  end
end
