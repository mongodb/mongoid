require "spec_helper"

describe Mongoid::Relations::Referenced::One do

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

    it "returns _id" do
      described_class.foreign_key_suffix.should == "_id"
    end
  end

  describe ".macro" do

    it "returns references_one" do
      described_class.macro.should == :references_one
    end
  end

  describe "#respond_to?" do

    let(:person) do
      Person.new
    end

    let!(:game) do
      person.build_game(:name => "Tron")
    end

    let(:document) do
      person.game
    end

    Mongoid::Document.public_instance_methods(true).each do |method|

      context "when checking #{method}" do

        it "returns true" do
          document.respond_to?(method).should be_true
        end
      end
    end
  end

  describe ".stores_foreign_key?" do

    it "returns false" do
      described_class.stores_foreign_key?.should == false
    end
  end

  describe ".valid_options" do

    it "returns the valid options" do
      described_class.valid_options.should ==
        [ :as, :autosave, :dependent, :foreign_key ]
    end
  end

  describe ".validation_default" do

    it "returns true" do
      described_class.validation_default.should eq(true)
    end
  end
end
