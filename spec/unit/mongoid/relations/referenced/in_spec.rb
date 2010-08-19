require "spec_helper"

describe Mongoid::Relations::Referenced::In do

  let(:klass) do
    Mongoid::Relations::Referenced::In
  end

  let(:binding_class) do
    Mongoid::Relations::Bindings::Referenced::In
  end

  let(:base) do
    Post.new
  end

  describe "#bind" do

    let(:document) do
      Person.new
    end

    let(:metadata) do
      stub(
        :extension? => false,
        :foreign_key_setter => "person_id=",
        :inverse => :post,
        :inverse_setter => "post="
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
      Mongoid::Relations::Builders::Referenced::In
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

    it "returns referenced_in" do
      klass.macro.should == :referenced_in
    end
  end

  describe ".stores_foreign_key?" do

    it "returns true" do
      klass.stores_foreign_key?.should == true
    end
  end

  describe "#substitute" do

    let(:document) do
      Person.new
    end

    let(:metadata) do
      stub(
        :extension? => false,
        :foreign_key_setter => "person_id=",
        :inverse => :post,
        :inverse_setter => "post="
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

      let(:new_person) do
        Person.new
      end

      it "binds the relation" do
        binding.expects(:bind)
        relation.substitute(new_person)
      end

      it "sets a new target" do
        binding.expects(:bind)
        relation.substitute(new_person)
        relation.target.should == new_person
      end
    end
  end

  describe "#unbind" do

    let(:document) do
      Person.new
    end

    let(:metadata) do
      stub(
        :extension? => false,
        :foreign_key_setter => "person_id=",
        :inverse => :post,
        :inverse_setter => "post="
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
  end
end
