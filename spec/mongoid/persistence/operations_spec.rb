require "spec_helper"

describe Mongoid::Persistence::Operations do

  let(:document) do
    Person.new
  end

  let(:klass) do
    Class.new do
      include Mongoid::Persistence::Operations
    end
  end

  describe "#collection" do

    let(:options) do
      { validate: true }
    end

    context "when the document is a root" do

      let(:operation) do
        klass.new(document, options)
      end

      let(:collection) do
        operation.collection
      end

      it "returns the root collection" do
        collection.name.should eq(document.collection.name)
      end
    end

    context "when the document is embedded" do

      let(:name) do
        document.build_name(first_name: "Syd")
      end

      let(:operation) do
        klass.new(name, options)
      end

      let(:collection) do
        operation.collection
      end

      it "returns the root collection" do
        collection.name.should eq(document.collection.name)
      end
    end
  end

  describe "#deletes" do

    context "when the child is an embeds one" do

      let(:child) do
        document.build_name(first_name: "Syd")
      end

      let(:operation) do
        klass.new(child)
      end

      let(:deletes) do
        operation.deletes
      end

      it "returns the delete atomic modifiers" do
        deletes.should eq(
          { "$unset" => { "name" => true } }
        )
      end
    end

    context "when the child is an embeds many" do

      let(:child) do
        document.addresses.build(street: "Unter den Linden")
      end

      let(:operation) do
        klass.new(child)
      end

      let(:deletes) do
        operation.deletes
      end

      it "returns the delete atomic modifiers" do
        deletes.should eq(
          { "$pull" => { "addresses" => { "_id" => "unter-den-linden" } } }
        )
      end
    end
  end

  describe "#inserts" do

    let(:child) do
      document.build_name(first_name: "Syd")
    end

    let(:operation) do
      klass.new(child)
    end

    let(:inserts) do
      operation.inserts
    end

    it "returns the insert atomic modifiers" do
      inserts.should eq(
        { "$set" => { "name" => { "first_name" => "Syd", "_id" => "Syd-" } } }
      )
    end
  end

  describe "#notifying_parent?" do

    let(:operation) do
      klass.new(document, options)
    end

    context "when the suppress option is true" do

      let(:options) do
        { suppress: true }
      end

      it "returns false" do
        operation.should_not be_notifying_parent
      end
    end

    context "when the suppress option is false" do

      let(:options) do
        { suppress: false }
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

    let(:options) do
      {}
    end

    let(:operation) do
      klass.new(document, options)
    end

    it "returns the options" do
      operation.options.should eq(options)
    end
  end

  describe "#parent" do

    let(:child) do
      document.addresses.build(street: "Unter den Linden")
    end

    let(:operation) do
      klass.new(child)
    end

    it "returns the document's parent" do
      operation.parent.should eq(document)
    end
  end

  describe "#selector" do

    let(:operation) do
      klass.new(document)
    end

    it "returns the document's atomic selector" do
      operation.selector.should eq(document.atomic_selector)
    end
  end

  describe "#updates" do

    context "when there are no conflicting mods" do

      let(:operation) do
        klass.new(document)
      end

      let(:updates) do
        operation.updates
      end

      it "returns the updates" do
        updates.should eq(document.atomic_updates)
      end
    end

    context "when conflicting mods exist" do

      let!(:document) do
        Person.new.tap do |person|
          person.new_record = false
          person.move_changes
        end
      end

      let!(:child) do
        document.addresses.build(street: "Unter den Linden").tap do |doc|
          doc.new_record = false
        end
      end

      let!(:conflict) do
        document.addresses.build(street: "Freiderichstr")
      end

      let(:operation) do
        klass.new(document)
      end

      let!(:updates) do
        operation.updates
      end

      let!(:conflicts) do
        operation.conflicts
      end

      it "returns the updates without conflicts" do
        updates.should eq(
          {
            "$set" => {
            "addresses.0.street" => "Unter den Linden",
            "addresses.0._id" => "unter-den-linden"
            }
          }
        )
      end

      it "sets the conflicts" do
        conflicts.should eq(
          {
            "$pushAll" => {
            "addresses" => [ { "street" => "Freiderichstr", "_id" => "freiderichstr" } ]
            }
          }
        )
      end
    end
  end

  describe "#validating?" do

    let(:operation) do
      klass.new(document, options)
    end

    context "when validate option is true" do

      let(:options) do
        { validate: true }
      end

      it "returns true" do
        operation.should be_validating
      end
    end

    context "when validate option is false" do

      let(:options) do
        { validate: false }
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
