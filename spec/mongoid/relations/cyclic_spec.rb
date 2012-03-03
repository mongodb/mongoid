require "spec_helper"

describe Mongoid::Relations::Cyclic do

  describe ".recursively_embeds_many" do

    context "when the name is inflected easily" do

      let(:document) do
        Role.new
      end

      it "creates the parent relation" do
        document.should respond_to(:parent_role)
      end

      it "creates the child relation" do
        document.should respond_to(:child_roles)
      end

      it "sets cyclic to true" do
        document.cyclic.should be_true
      end
    end

    context "when the name is not inflected easily" do

      let(:document) do
        Entry.new
      end

      it "creates the parent relation" do
        document.should respond_to(:parent_entry)
      end

      it "creates the child relation" do
        document.should respond_to(:child_entries)
      end

      it "sets cyclic to true" do
        document.cyclic.should be_true
      end
    end

    context "when the document is namespaced" do

      module Trees
        class Node
          include Mongoid::Document
          recursively_embeds_many

          field :name, type: String

          def is_root?
            parent_node.nil?
          end
        end
      end

      let(:document) do
        Trees::Node.new
      end

      it "creates the parent relation" do
        document.should respond_to(:parent_node)
      end

      it "creates the child relation" do
        document.should respond_to(:child_nodes)
      end

      it "sets cyclic to true" do
        document.cyclic.should be_true
      end
    end

    context "when the classes are namespaced" do

      let(:document) do
        Fruits::Apple.new
      end

      it "creates the parent relation" do
        document.should respond_to(:parent_apple)
      end

      it "creates the child relation" do
        document.should respond_to(:child_apples)
      end

      it "sets cyclic to true" do
        document.cyclic.should be_true
      end
    end

    context "when cascading callbacks are enabled" do

      let(:document) do
        Fruits::Pineapple.new
      end

      it "creates relation with cascading callbacks enabled" do
        document.class.relations['child_pineapples'].should be_cascading_callbacks
      end
    end
  end

  describe ".recursively_embeds_one" do

    let(:document) do
      Shelf.new
    end

    it "creates the parent relation" do
      document.should respond_to(:parent_shelf)
    end

    it "creates the child relation" do
      document.should respond_to(:child_shelf)
    end

    it "sets cyclic to true" do
      document.cyclic.should be_true
    end

    context "when cascading callbacks are enabled" do

      let(:document) do
        Fruits::Mango.new
      end

      it "creates relation with cascading callbacks enabled" do
        document.class.relations['child_mango'].should be_cascading_callbacks
      end
    end
  end

  context "when building a namespaced hierarchy" do

    let(:root) do
      Trees::Node.new(name: "root")
    end

    let!(:child_one) do
      root.child_nodes.build(name: "first_child")
    end

    let!(:child_two) do
      root.child_nodes.build(name: "second_child")
    end

    it "sets the parent node" do
      child_one.parent_node.should eq(root)
    end
  end
end
