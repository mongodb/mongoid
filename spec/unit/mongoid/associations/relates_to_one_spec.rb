require "spec_helper"

describe Mongoid::Associations::RelatesToOne do

  describe ".initialize" do

    context "when related id has been set" do

      before do
        @document = stub(:game_id => "5")
        @options = Mongoid::Associations::Options.new(:name => :game)
        @related = stub
      end

      it "finds the object by id" do
        Game.expects(:find).with(@document.game_id).returns(@related)
        association = Mongoid::Associations::RelatesToOne.new(@document, "5", @options)
        association.should == @related
      end

    end

  end

  describe ".instantiate" do

    context "when foreign key is not nil" do

      before do
        @document = stub(:game_id => "5")
        @options = Mongoid::Associations::Options.new(:name => :game)
      end

      it "delegates to new" do
        Mongoid::Associations::RelatesToOne.expects(:new).with(@document, "5", @options)
        Mongoid::Associations::RelatesToOne.instantiate(@document, @options)
      end

    end

    context "when foreign key is nil" do

      before do
        @document = stub(:game_id => nil)
        @options = Mongoid::Associations::Options.new(:name => :game)
      end

      it "returns nil" do
        Mongoid::Associations::RelatesToOne.instantiate(@document, @options).should be_nil
      end

    end

  end

  describe "#method_missing" do

    before do
      @game = Game.new(:score => 5000)
      @document = stub(:game_id => "5")
      @options = Mongoid::Associations::Options.new(:name => :game)
      Game.expects(:find).with(@document.game_id).returns(@game)
      @association = Mongoid::Associations::RelatesToOne.new(@document, "5", @options)
    end

    context "when getting values" do

      it "delegates to the document" do
        @association.score.should == 5000
      end

    end

    context "when setting values" do

      it "delegates to the document" do
        @association.score = 400
        @association.score.should == 400
      end

    end

  end

  describe ".macro" do

    it "returns :relates_to_one" do
      Mongoid::Associations::RelatesToOne.macro.should == :relates_to_one
    end

  end

  describe ".update" do

    before do
      @related = stub(:id => "5")
      @parent = Person.new
      @options = Mongoid::Associations::Options.new(:name => :game)
    end

    it "sets the related object id on the parent" do
      Mongoid::Associations::RelatesToOne.update(@related, @parent, @options)
      @parent.game_id.should == "5"
    end

    it "returns the related object" do
      Mongoid::Associations::RelatesToOne.update(@related, @parent, @options).should == @related
    end

  end

end
