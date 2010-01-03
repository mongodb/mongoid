require "spec_helper"

describe Mongoid::Associations::HasOneRelated do

  let(:document) { stub(:id => "1") }
  let(:options) { Mongoid::Associations::Options.new(:name => :game) }

  describe "#build" do

    before do
      @parent = stub(:id => "5", :class => Person)
      Game.expects(:first).returns(nil)
      @association = Mongoid::Associations::HasOneRelated.new(@parent, options)
    end

    it "adds a new object to the association" do
      @association.build(:score => 100)
      @association.score.should == 100
    end

    it "sets the parent object id on the child" do
      @association.build(:score => 100)
      @association.person_id.should == @parent.id
    end

    it "sets the parent object reference on the child" do
      @association.build(:score => 100)
      @association.person.should == @parent
    end

  end

  describe "#create" do

    before do
      @parent = stub(:id => "5", :class => Person)
      Game.expects(:first).returns(nil)
      Mongoid::Commands::Save.expects(:execute)
      @association = Mongoid::Associations::HasOneRelated.new(@parent, options)
    end

    it "adds a new object to the association" do
      @association.create(:score => 100)
      @association.score.should == 100
    end

    it "sets the parent object id on the child" do
      @association.create(:score => 100)
      @association.person_id.should == @parent.id
    end

    it "returns the new document" do
      @association.create(:score => 100).should be_a_kind_of(Game)
    end

  end

  describe ".initialize" do

    before do
      @person = Person.new
      @game = stub
    end

    it "finds the association game by the parent key" do
      Game.expects(:first).with(:conditions => { "person_id"=> @person.id }).returns(@game)
      @person.game.should == @game
    end

  end

  describe ".instantiate" do

    it "delegates to new" do
      Mongoid::Associations::HasOneRelated.expects(:new).with(document, options)
      Mongoid::Associations::HasOneRelated.instantiate(document, options)
    end

  end

  describe "#method_missing" do

    before do
      @person = Person.new
      @game = stub
    end

    it "delegates to the documet" do
      Game.expects(:first).with(:conditions => { "person_id"=> @person.id }).returns(@game)
      @game.expects(:strange_method)
      association = Mongoid::Associations::HasOneRelated.instantiate(@person, options)
      association.strange_method
    end

  end

  describe ".macro" do

    it "returns :has_one_related" do
      Mongoid::Associations::HasOneRelated.macro.should == :has_one_related
    end

  end

  describe "#nil?" do

    before do
      @person = Person.new
      @game = stub
      Game.expects(:first).with(:conditions => { "person_id"=> @person.id }).returns(nil)
    end

    it "delegates to the document" do
      association = Mongoid::Associations::HasOneRelated.instantiate(@person, options)
      association.should be_nil
    end

  end

  describe ".update" do

    before do
      @person = Person.new
      @game = stub
    end

    it "sets the parent on the child association" do
      @game.expects(:person=).with(@person)
      Mongoid::Associations::HasOneRelated.update(@game, @person, options)
    end

    it "returns the child" do
      @game.expects(:person=).with(@person)
      Mongoid::Associations::HasOneRelated.update(@game, @person, options).should == @game
    end

  end

end
