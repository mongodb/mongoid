require "spec_helper"

describe Mongoid::Associations::MetaData do

  before do
    @extension = lambda { "Test" }
  end

  let(:association) do
    Mongoid::Associations::ReferencesMany
  end

  let(:options) do
    Mongoid::Associations::Options.new(
      :name => :games,
      :extend => @extension,
      :foreign_key => "person_id",
      :inverse_of => :people
    )
  end

  let(:metadata) do
    Mongoid::Associations::MetaData.new(association, options)
  end

  describe "#embedded?" do

    context "when association is embedded" do

      before do
        @embedded = Mongoid::Associations::EmbedsOne
        @meta = Mongoid::Associations::MetaData.new(@embedded, nil)
      end

      it "returns true" do
        @meta.embedded?.should == true
      end
    end

    context "when association is not embedded" do

      it "returns false" do
        metadata.embedded?.should == false
      end
    end
  end

  describe "#extension" do

    it "delegates to the options" do
      metadata.extension.should == @extension
    end
  end

  describe "#foreign_key" do

    it "delegates to the options" do
      metadata.foreign_key.should == "person_id"
    end
  end

  describe "#inverse_of" do

    it "delegates to the options" do
      metadata.inverse_of.should == :people
    end
  end

  describe "#klass" do

    it "returns the associated klass" do
      metadata.klass.should == Game
    end
  end

  describe "#macro" do

    it "returns the association macro" do
      metadata.macro.should == :references_many
    end
  end

  describe "#name" do

    it "delegates to the options" do
      metadata.name.should == "games"
    end
  end

  describe "#options" do

    it "returns the association options" do
      metadata.options.should == options
    end
  end

  describe "#polymorphic" do

    it "delegates to the options" do
      metadata.polymorphic.should be_false
    end
  end

  describe "#association" do

    it "returns the association type" do
      metadata.association.should == Mongoid::Associations::ReferencesMany
    end
  end
end
