require "spec_helper"

describe Mongoid::Validations::UniquenessValidator do

  describe "#validate_each" do

    let(:validator) do
      described_class.new(options)
    end

    context "when the document is the root" do

      let(:dictionary) do
        Dictionary.new(:year => 1999, :name => "")
      end

      let(:criteria) do
        stub
      end

      before do
        validator.setup(Dictionary)
      end

      context "when no options provided" do

        let(:options) do
          { :attributes => dictionary.attributes }
        end

        let(:unscoped) do
          stub
        end

        before do
          Dictionary.expects(:unscoped).returns(unscoped)
          unscoped.expects(:where).with(:name => "Oxford").returns(criteria)
          criteria.expects(:exists?).returns(true)
          validator.validate_each(dictionary, :name, "Oxford")
        end

        it "checks existance of the document" do
          dictionary.errors[:name].should eq([ "is already taken" ])
        end
      end

      context "when case sensitive is true" do

        let(:options) do
          { :attributes => dictionary.attributes }
        end

        let(:unscoped) do
          stub
        end

        before do
          Dictionary.expects(:unscoped).returns(unscoped)
          unscoped.expects(:where).with(:name => "Oxford").returns(criteria)
          criteria.expects(:exists?).returns(true)
          validator.validate_each(dictionary, :name, "Oxford")
        end

        it "checks existance of the exact value" do
          dictionary.errors[:name].should eq([ "is already taken" ])
        end
      end

      context "when case sensitive is false" do

        let(:options) do
          { :attributes => dictionary.attributes, :case_sensitive => false }
        end

        let(:unscoped) do
          stub
        end

        before do
          Dictionary.expects(:unscoped).returns(unscoped)
          unscoped.expects(:where).with(:name => /^Oxford$/i).returns(criteria)
          criteria.expects(:exists?).returns(true)
          validator.validate_each(dictionary, :name, "Oxford")
        end

        it "checks existance of a case insensitive regex" do
          dictionary.errors[:name].should eq([ "is already taken" ])
        end
      end

      context "when providing a scope" do

        let(:options) do
          { :attributes => dictionary.attributes, :scope => :year }
        end

        let(:unscoped) do
          stub
        end

        before do
          Dictionary.expects(:unscoped).returns(unscoped)
          unscoped.expects(:where).with(:name => "Oxford").returns(criteria)
          criteria.expects(:where).with(:year => dictionary.year).returns(criteria)
          criteria.expects(:exists?).returns(true)
          validator.validate_each(dictionary, :name, "Oxford")
        end

        it "checks existance within the scope" do
          dictionary.errors[:name].should eq([ "is already taken" ])
        end
      end

      context "when providing a message" do

        let(:options) do
          { :attributes => dictionary.attributes, :message => "my test message" }
        end

        let(:unscoped) do
          stub
        end

        before do
          Dictionary.expects(:unscoped).returns(unscoped)
          unscoped.expects(:where).with(:name => "Oxford").returns(criteria)
          criteria.expects(:exists?).returns(true)
          validator.validate_each(dictionary, :name, "Oxford")
        end

        it "checks existance with a message" do
          dictionary.errors[:name].should eq([ "my test message" ])
        end
      end
    end

    context "when using paranoia" do
      before do
        Dictionary.class_eval do
          include Mongoid::Paranoia
          validates_uniqueness_of :name
        end
      end

      context "when the document is unique in not deleted" do
        before do
          Dictionary.create(:name => "Oxford").destroy
        end

        let(:dictionary) do
          Dictionary.new(:name => "Oxford")
        end

        it "returns true" do
          dictionary.should be_valid
        end
      end
    end

    context "when the document is embedded" do

      let(:word) do
        Word.new
      end

      let(:definition) do
        word.definitions.build(:description => "")
      end

      let(:criteria) do
        stub
      end

      before do
        validator.setup(Definition)
      end

      context "when no options provided" do

        let(:options) do
          { :attributes => definition.attributes }
        end

        before do
          word.definitions.expects(:unscoped).returns(criteria)
          criteria.expects(:where).with(
            :description => "Testy"
          ).returns(criteria)
          criteria.expects(:count).returns(2)
          validator.validate_each(definition, :description, "Testy")
        end

        it "checks existance of the document" do
          definition.errors[:description].should eq([ "is already taken" ])
        end
      end

      context "when case sensitive is true" do

        let(:options) do
          { :attributes => definition.attributes }
        end

        before do
          word.definitions.expects(:unscoped).returns(criteria)
          criteria.expects(:where).with(
            :description => "Testy"
          ).returns(criteria)
          criteria.expects(:count).returns(2)
          validator.validate_each(definition, :description, "Testy")
        end

        it "checks existance of the exact value" do
          definition.errors[:description].should eq([ "is already taken" ])
        end
      end

      context "when case sensitive is false" do

        let(:options) do
          { :attributes => definition.attributes, :case_sensitive => false }
        end

        before do
          word.definitions.expects(:unscoped).returns(criteria)
          criteria.expects(:where).with(
            :description => /^Testy$/i
          ).returns(criteria)
          criteria.expects(:count).returns(2)
          validator.validate_each(definition, :description, "Testy")
        end

        it "checks existance of a case insensitive regex" do
          definition.errors[:description].should eq([ "is already taken" ])
        end
      end

      context "when providing a scope" do

        let(:options) do
          { :attributes => definition.attributes, :scope => :part }
        end

        before do
          word.definitions.expects(:unscoped).returns(criteria)
          criteria.expects(:where).with(
            :description => "Testy"
          ).returns(criteria)
          criteria.expects(:where).with(:part => definition.part).returns(criteria)
          criteria.expects(:count).returns(2)
          validator.validate_each(definition, :description, "Testy")
        end

        it "checks existance within the scope" do
          definition.errors[:description].should eq([ "is already taken" ])
        end
      end
    end
  end
end
