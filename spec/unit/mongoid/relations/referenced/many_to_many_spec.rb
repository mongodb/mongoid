require "spec_helper"

describe Mongoid::Relations::Referenced::ManyToMany do

  describe ".builder" do

    let(:builder_klass) do
      Mongoid::Relations::Builders::Referenced::ManyToMany
    end

    let(:document) do
      stub
    end

    let(:metadata) do
      stub(:extension? => false)
    end

    it "returns the embedded in builder" do
      described_class.builder(metadata, document).should
        be_a_kind_of(builder_klass)
    end
  end

  describe ".embedded?" do

    it "returns false" do
      described_class.should_not be_embedded
    end
  end

  describe ".foreign_key_suffix" do

    it "returns _ids" do
      described_class.foreign_key_suffix.should == "_ids"
    end
  end

  describe ".macro" do

    it "returns references_and_referenced_in_many" do
      described_class.macro.should == :references_and_referenced_in_many
    end
  end

  describe "#respond_to?" do

    let(:person) do
      Person.new
    end

    let(:preferences) do
      person.preferences
    end

    Array.public_instance_methods.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          preferences.respond_to?(method).should be_true
        end
      end
    end

    Mongoid::Relations::Referenced::Many.public_instance_methods.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          preferences.respond_to?(method).should be_true
        end
      end
    end

    Preference.scopes.keys.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          preferences.respond_to?(method).should be_true
        end
      end
    end
  end

  describe ".stores_foreign_key?" do

    it "returns true" do
      described_class.stores_foreign_key?.should == true
    end
  end

  describe ".valid_options" do

    it "returns the valid options" do
      described_class.valid_options.should ==
        [ :autosave, :dependent, :foreign_key, :index, :order ]
    end
  end

  describe ".validation_default" do

    it "returns true" do
      described_class.validation_default.should eq(true)
    end
  end
end
