require "spec_helper"

describe Mongoid::Relations::Embedded::One do

  let(:klass) do
    Mongoid::Relations::Embedded::One
  end

  let(:binding_klass) do
    Mongoid::Relations::Bindings::Embedded::One
  end

  let(:builder_klass) do
    Mongoid::Relations::Builders::Embedded::One
  end

  let(:nested_builder_klass) do
    Mongoid::Relations::Builders::NestedAttributes::One
  end

  let(:binding) do
    stub
  end

  let(:base) do
    Person.new
  end

  let(:target) do
    Name.new
  end

  let(:metadata) do
    Mongoid::Relations::Metadata.new(
      :relation => klass,
      :inverse_class_name => "Person",
      :name => :name,
      :as => :namable
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

      context "when the base is persisted" do

        before do
          base.expects(:persisted?).returns(true)
        end

        it "saves the target" do
          target.expects(:save).returns(true)
          relation.bind
        end
      end

      context "when the base is not persisted" do

        it "does not save the target" do
          target.expects(:save).never
          relation.bind
        end
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
      relation.target._parent.should == base
    end
  end

  describe ".macro" do

    it "returns embeds_one" do
      klass.macro.should == :embeds_one
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

    context "when the base is persisted" do

      context "when the target has not been destroyed" do

        before do
          base.expects(:persisted?).returns(true)
        end

        it "deletes the target" do
          target.expects(:delete).returns(true)
          relation.unbind(target)
        end
      end

      context "when the target is already destroyed" do

        before do
          base.expects(:persisted?).returns(true)
          target.expects(:destroyed?).returns(true)
        end

        it "does not delete the target" do
          target.expects(:delete).never
          relation.unbind(target)
        end
      end
    end

    context "when the base is not persisted" do

      it "does not delete the target" do
        target.expects(:delete).never
        relation.unbind(target)
      end
    end
  end
end
