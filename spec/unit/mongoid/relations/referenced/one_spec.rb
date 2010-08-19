require "spec_helper"

describe Mongoid::Relations::Referenced::One do

  let(:klass) do
    Mongoid::Relations::Referenced::One
  end

  let(:binding_class) do
    Mongoid::Relations::Bindings::Referenced::One
  end

  let(:base) do
    Person.new
  end

  describe "#bind" do

    let(:document) do
      Post.new
    end

    let(:metadata) do
      stub(
        :extension? => false,
        :foreign_key_setter => "person_id=",
        :inverse => :person,
        :inverse_setter => "person="
      )
    end

    let(:binding) do
      stub
    end

    let(:relation) do
      klass.new(base, document, metadata)
    end

    before do
      binding_class.expects(:new).returns(binding)
    end

    it "delegates to the binding" do
      binding.expects(:bind)
      relation.bind
    end

    context "when the base is persisted" do

      before do
        base.new_record = false
        binding.expects(:bind)
      end

      it "saves the target" do
        document.expects(:save)
        relation.bind
      end
    end
  end

  describe ".builder" do

    let(:builder_klass) do
      Mongoid::Relations::Builders::Referenced::One
    end

    let(:document) do
      stub
    end

    let(:metadata) do
      stub(:extension? => false)
    end

    it "returns the embedded in builder" do
      klass.builder(metadata, document).should
        be_a_kind_of(builder_klass)
    end
  end

  describe ".embedded?" do

    it "returns false" do
      klass.should_not be_embedded
    end
  end

  describe ".foreign_key_suffix" do

    it "returns _id" do
      klass.foreign_key_suffix.should == "_id"
    end
  end

  describe ".macro" do

    it "returns references_one" do
      klass.macro.should == :references_one
    end
  end

  describe ".stores_foreign_key?" do

    it "returns false" do
      klass.stores_foreign_key?.should == false
    end
  end

  context "properties" do

    let(:document) do
      Post.new
    end

    let(:metadata) do
      stub(
        :extension? => false,
        :foreign_key_setter => "person_id=",
        :inverse => :person,
        :inverse_setter => "person="
      )
    end

    let(:relation) do
      klass.new(base, document, metadata)
    end

    describe "#metadata" do

      it "returns the relation's metadata" do
        relation.metadata.should == metadata
      end
    end

    describe "#target" do

      it "returns the relation's target" do
        relation.target.should == document
      end
    end
  end

  describe "#substitute" do

    let(:document) do
      Post.new
    end

    let(:metadata) do
      stub(
        :extension? => false,
        :foreign_key_setter => "person_id=",
        :inverse => :person,
        :inverse_setter => "person="
      )
    end

    let(:binding) do
      stub
    end

    let(:relation) do
      klass.new(base, document, metadata)
    end

    before do
      binding_class.expects(:new).returns(binding)
    end

    context "when the target is nil" do

      it "unbinds the relation" do
        binding.expects(:unbind)
        relation.substitute(nil)
      end

      it "returns nil" do
        binding.expects(:unbind)
        relation.substitute(nil).should be_nil
      end
    end

    context "when the target is not nil" do

      let(:new_post) do
        Post.new
      end

      it "binds the relation" do
        binding.expects(:bind)
        relation.substitute(new_post)
      end

      it "sets a new target" do
        binding.expects(:bind)
        relation.substitute(new_post)
        relation.target.should == new_post
      end
    end
  end

  describe "#unbind" do

    let(:document) do
      Post.new
    end

    let(:metadata) do
      stub(
        :extension? => false,
        :foreign_key_setter => "person_id=",
        :inverse => :person,
        :inverse_setter => "person="
      )
    end

    let(:binding) do
      stub
    end

    let(:relation) do
      klass.new(base, document, metadata)
    end

    before do
      binding_class.expects(:new).returns(binding)
    end

    it "delegates to the binding" do
      binding.expects(:unbind)
      relation.unbind
    end

    context "when the base is persisted" do

      before do
        base.new_record = false
        binding.expects(:unbind)
      end

      it "deletes the target" do
        document.expects(:delete)
        relation.unbind
      end
    end
  end
end
