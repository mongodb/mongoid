require "spec_helper"

describe Mongoid::Relations::Embedded::One do

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
      :relation => described_class,
      :inverse_class_name => "Person",
      :name => :name,
      :as => :namable
    )
  end

  describe "#===" do

    let(:relation) do
      described_class.new(base, target, metadata)
    end

    context "when the proxied document is same class" do

      it "returns true" do
        (relation === Name.new).should be_true
      end
    end
  end

  describe ".builder" do

    it "returns the embedded one builder" do
      described_class.builder(metadata, target).should be_a(builder_klass)
    end
  end

  describe ".embedded?" do

    it "returns true" do
      described_class.should be_embedded
    end
  end

  describe "#initialize" do

    let(:relation) do
      described_class.new(base, target, metadata)
    end

    it "parentizes the child" do
      relation.target._parent.should == base
    end
  end

  describe ".macro" do

    it "returns embeds_one" do
      described_class.macro.should == :embeds_one
    end
  end

  describe ".nested_builder" do

    let(:attributes) do
      {}
    end

    it "returns the single nested builder" do
      described_class.nested_builder(metadata, attributes, {}).should
        be_a(nested_builder_klass)
    end
  end

  describe "#respond_to?" do

    let(:person) do
      Person.new
    end

    let!(:name) do
      person.build_name(:first_name => "Tony")
    end

    let(:document) do
      person.name
    end

    Mongoid::Document.public_instance_methods(true).each do |method|

      context "when checking #{method}" do

        it "returns true" do
          document.respond_to?(method).should be_true
        end
      end
    end

    it "responds to persisted?" do
      document.should respond_to(:persisted?)
    end
  end

  describe ".valid_options" do

    it "returns the valid options" do
      described_class.valid_options.should ==
        [ :as, :cyclic ]
    end
  end

  describe ".validation_default" do

    it "returns true" do
      described_class.validation_default.should eq(true)
    end
  end
end
