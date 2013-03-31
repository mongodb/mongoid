require "spec_helper"

describe Mongoid::Threaded do

  let(:object) do
    stub
  end

  describe "#begin" do

    before do
      described_class.begin_execution("load")
    end

    after do
      described_class.stack("load").clear
    end

    it "adds a boolen to the load stack" do
      expect(described_class.stack("load")).to eq([ true ])
    end
  end

  describe "#executing?" do

    context "when loading is not set" do

      it "returns false" do
        expect(described_class).to_not be_executing(:load)
      end
    end

    context "when the stack has elements" do

      before do
        Thread.current["[mongoid]:load-stack"] = [ true ]
      end

      after do
        Thread.current["[mongoid]:load-stack"] = []
      end

      it "returns true" do
        expect(described_class).to be_executing(:load)
      end
    end

    context "when the stack has no elements" do

      before do
        Thread.current["[mongoid]:load-stack"] = []
      end

      it "returns false" do
        expect(described_class).to_not be_executing(:load)
      end
    end
  end

  describe "#stack" do

    context "when no stack has been initialized" do

      let(:loading) do
        described_class.stack("load")
      end

      it "returns an empty stack" do
        expect(loading).to be_empty
      end
    end

    context "when a stack has been initialized" do

      before do
        Thread.current["[mongoid]:load-stack"] = [ true ]
      end

      let(:loading) do
        described_class.stack("load")
      end

      after do
        Thread.current["[mongoid]:load-stack"] = []
      end

      it "returns the stack" do
        expect(loading).to eq([ true ])
      end
    end
  end

  describe "#exit" do

    before do
      described_class.begin_execution("load")
      described_class.exit_execution("load")
    end

    after do
      described_class.stack("load").clear
    end

    it "removes a boolen from the stack" do
      expect(described_class.stack("load")).to be_empty
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
      expect(described_class.persistence_options(Band)).to be_nil
    end

    it "returns true" do
      expect(cleared).to be_true
    end
  end

  describe "#identity_map" do

    before do
      Thread.current["[mongoid]:identity-map"] = object
    end

    after do
      Thread.current["[mongoid]:identity-map"] = nil
    end

    it "returns the object with the identity map key" do
      expect(described_class.identity_map).to eq(object)
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
      expect(options).to eq({ safe: { w: 3 }})
    end
  end

  describe "#scope_stack" do

    it "returns the default with the scope stack key" do
      expect(described_class.scope_stack).to be_a(Hash)
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
      expect(described_class.timeless).to be_true
    end
  end

  describe "#timestamping?" do

    context "when timeless is not set" do

      it "returns true" do
        expect(described_class).to be_timestamping
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
        expect(described_class).to_not be_timestamping
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
      expect(described_class.validations_for(Person)).to eq([ person.id ])
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
      expect(described_class.validations_for(Person)).to be_empty
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
        expect(described_class.validated?(person)).to be_true
      end
    end

    context "when the document is not validated" do

      it "returns false" do
        expect(described_class.validated?(person)).to be_false
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
      expect(described_class.autosaves_for(Person)).to eq([ person.id ])
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
      expect(described_class.autosaves_for(Person)).to be_empty
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
        expect(described_class.autosaved?(person)).to be_true
      end
    end

    context "when the document is not autosaved" do

      it "returns false" do
        expect(described_class.autosaved?(person)).to be_false
      end
    end
  end
end
