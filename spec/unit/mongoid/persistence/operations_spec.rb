require "spec_helper"

describe Mongoid::Persistence::Operations do

  let(:document) do
    Person.new
  end

  before(:all) do
    @klass = Class.new do
      include Mongoid::Persistence::Operations
    end
  end

  describe "#collection" do

    let(:options) do
      { :validate => true }
    end

    context "when the document is a root" do

      let(:operation) do
        @klass.new(document, options)
      end

      let(:collection) do
        operation.collection
      end

      it "returns the root collection" do
        collection.should eq(document.collection)
      end
    end

    context "when the document is embedded" do

      let(:name) do
        document.build_name(:first_name => "Syd")
      end

      let(:operation) do
        @klass.new(name, options)
      end

      let(:collection) do
        operation.collection
      end

      it "returns the root collection" do
        collection.should eq(document.collection)
      end
    end
  end

  describe "#inserts" do

    let(:child) do
      document.build_name(:first_name => "Syd")
    end

    let(:operation) do
      @klass.new(child)
    end

    let(:inserts) do
      operation.inserts
    end

    it "returns the insert atomic modifiers" do
      inserts.should eq(
        { "$set" => { "name" => { "first_name" => "Syd", "_id" => "syd" } } }
      )
    end
  end

  describe "#notifying_parent?" do

    let(:operation) do
      @klass.new(document, options)
    end

    context "when the suppress option is true" do

      let(:options) do
        { :suppress => true }
      end

      it "returns false" do
        operation.should_not be_notifying_parent
      end
    end

    context "when the suppress option is false" do

      let(:options) do
        { :suppress => false }
      end

      it "returns true" do
        operation.should be_notifying_parent
      end
    end

    context "when the suppress option is nil" do

      let(:options) do
        {}
      end

      it "returns true" do
        operation.should be_notifying_parent
      end
    end
  end

  describe "#options" do

    let(:operation) do
      @klass.new(document, options)
    end

    context "safe is true" do

      let(:options) do
        { :safe => true }
      end

      let(:opts) do
        operation.options
      end

      it "returns the safe options" do
        opts.should eq(options)
      end
    end

    context "when safe is a hash" do

      let(:options) do
        { :safe => { :w => 2 } }
      end

      let(:opts) do
        operation.options
      end

      it "returns the safe options" do
        opts.should eq(options)
      end
    end

    context "when safe is false" do

      let(:options) do
        { :safe => false }
      end

      let(:opts) do
        operation.options
      end

      it "returns the safe options" do
        opts.should eq(options)
      end
    end

    context "when safe is nil" do

      let(:options) do
        {}
      end

      let(:opts) do
        operation.options
      end

      context "when persisting in safe mode" do

        before do
          Mongoid.persist_in_safe_mode = true
        end

        after do
          Mongoid.persist_in_safe_mode = false
        end

        it "returns :safe => true" do
          opts.should eq({ :safe => true })
        end
      end

      context "when not persisting in safe mode" do

        before do
          Mongoid.persist_in_safe_mode = false
        end

        it "returns :safe => false" do
          opts.should eq({ :safe => false })
        end
      end
    end
  end

  describe "#parent" do

    let(:child) do
      document.addresses.build(:street => "Unter den Linden")
    end

    let(:operation) do
      @klass.new(child)
    end

    it "returns the document's parent" do
      operation.parent.should eq(document)
    end
  end

  describe "#validating?" do

    let(:operation) do
      @klass.new(document, options)
    end

    context "when validate option is true" do

      let(:options) do
        { :validate => true }
      end

      it "returns true" do
        operation.should be_validating
      end
    end

    context "when validate option is false" do

      let(:options) do
        { :validate => false }
      end

      it "returns false" do
        operation.should_not be_validating
      end
    end

    context "when validate option is nil" do

      let(:options) do
        {}
      end

      it "returns true" do
        operation.should be_validating
      end
    end
  end
end
