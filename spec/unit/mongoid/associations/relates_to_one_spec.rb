require File.expand_path(File.join(File.dirname(__FILE__), "/../../../spec_helper.rb"))

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
        association = Mongoid::Associations::RelatesToOne.new(@document, @options)
        association.should == @related
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

  end

end
