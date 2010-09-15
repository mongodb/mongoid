require "spec_helper"

describe Mongoid::Relations::Embedded::In do

  let(:klass) do
    Mongoid::Relations::Embedded::In
  end

  let(:binding_klass) do
    Mongoid::Relations::Bindings::Embedded::In
  end

  let(:builder_klass) do
    Mongoid::Relations::Builders::Embedded::In
  end

  let(:nested_builder_klass) do
    Mongoid::Relations::Builders::NestedAttributes::One
  end

  let(:binding) do
    stub
  end

  let(:base) do
    Name.new
  end

  let(:target) do
    Person.new
  end

  let(:metadata) do
    Mongoid::Relations::Metadata.new(
      :relation => klass,
      :inverse_class_name => "Name",
      :name => :namable,
      :polymorphic => true
    )
  end

  describe "#bind" do

    let(:relation) do
      klass.new(base, target, metadata)
    end

    before do
      binding_klass.expects(:new).returns(binding)
      binding.expects(:bind).returns(true)
    end

    context "when building" do

      it "does not save the document" do
        target.expects(:save).never
        relation.bind(true)
      end
    end

    context "when not building" do

      it "does not save the target" do
        target.expects(:save).never
        relation.bind
      end
    end
  end

  describe ".builder" do

    it "returns the embedded one builder" do
      klass.builder(metadata, target).should be_a(builder_klass)
    end
  end

  describe ".embedded?" do

    it "returns true" do
      klass.should be_embedded
    end
  end

  describe "#initialize" do

    let(:relation) do
      klass.new(base, target, metadata)
    end

    it "parentizes the child" do
      relation.base._parent.should == target
    end
  end

  describe ".macro" do

    it "returns embeds_one" do
      klass.macro.should == :embedded_in
    end
  end

  describe ".nested_builder" do

    let(:attributes) do
      {}
    end

    it "returns the single nested builder" do
      klass.nested_builder(metadata, attributes, {}).should
        be_a(nested_builder_klass)
    end
  end

  describe "#substitute" do

    let(:relation) do
      klass.new(base, target, metadata)
    end

    context "when passing a document" do

      let(:document) do
        Name.new(:first_name => "Durran")
      end

      before do
        binding_klass.expects(:new).returns(binding)
        binding.expects(:bind).returns(true)
        @substitute = relation.substitute(document)
      end

      it "sets a new target" do
        relation.target.should == document
      end

      it "returns the relation" do
        @substitute.should == relation
      end
    end

    context "when passing nil" do

      before do
        binding_klass.expects(:new).returns(binding)
        binding.expects(:unbind)
        @substitute = relation.substitute(nil)
      end

      it "sets a new target" do
        relation.target.should == nil
      end

      it "returns the relation" do
        @substitute.should be_nil
      end
    end
  end

  describe "#unbind" do

    let(:relation) do
      klass.new(base, target, metadata)
    end

    context "when the target is persisted" do

      context "when the base has not been destroyed" do

        before do
          target.expects(:persisted?).returns(true)
        end

        it "deletes the base" do
          base.expects(:delete).returns(true)
          relation.unbind(target)
        end
      end

      context "when the base is already destroyed" do

        before do
          target.expects(:persisted?).returns(true)
          base.expects(:destroyed?).returns(true)
        end

        it "does not delete the target" do
          base.expects(:delete).never
          relation.unbind(target)
        end
      end
    end

    context "when the target is not persisted" do

      it "does not delete the base" do
        base.expects(:delete).never
        relation.unbind(target)
      end
    end
  end
end
