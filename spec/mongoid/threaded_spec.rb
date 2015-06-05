require "spec_helper"

describe Mongoid::Threaded do

  let(:object) do
    double
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
        expect(described_class.validated?(person)).to be true
      end
    end

    context "when the document is not validated" do

      it "returns false" do
        expect(described_class.validated?(person)).to be false
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
        expect(described_class.autosaved?(person)).to be true
      end
    end

    context "when the document is not autosaved" do

      it "returns false" do
        expect(described_class.autosaved?(person)).to be false
      end
    end
  end
end
