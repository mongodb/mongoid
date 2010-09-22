require "spec_helper"

describe Mongoid::Associations::ReferencesOne do

  let(:document) { stub(:id => "4c52c439931a90ab29000001") }
  let(:block) do
    Proc.new do
      def extension
        "Testing"
      end
    end
  end
  let(:options) do
    Mongoid::Associations::Options.new(:name => :game, :extend => block, :foreign_key => "person_id")
  end

  describe "#build" do

    before do
      @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person)
      Game.expects(:first).returns(nil)
      @association = Mongoid::Associations::ReferencesOne.new(@parent, options)
    end

    it "adds a new object to the association" do
      @association.build(:score => 100)
      @association.score.should == 100
    end

    it "sets the parent object id on the child" do
      @association.build(:score => 100)
      @association.person_id.should == BSON::ObjectId(@parent.id)
    end

    it "sets the parent object reference on the child" do
      @association.build(:score => 100)
      @association.person.should == @parent
    end

  end

  describe "#create" do

    before do
      @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person)
      @insert = stub
      Game.expects(:first).returns(nil)
      Mongoid::Persistence::Insert.expects(:new).returns(@insert)
      @insert.expects(:persist).returns(Person.new)
      @association = Mongoid::Associations::ReferencesOne.new(@parent, options)
    end

    it "can be called with no arguments" do
      expect { @association.create }.to_not raise_error
    end

    it "adds a new object to the association" do
      @association.create(:score => 100)
      @association.score.should == 100
    end

    it "sets the parent object id on the child" do
      @association.create(:score => 100)
      @association.person_id.should == BSON::ObjectId(@parent.id)
    end

    it "returns the new document" do
      @association.create(:score => 100).should be_a_kind_of(Game)
    end

  end

  describe "#id" do

    before do
      @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person)
      @game = Game.new
      Game.expects(:first).returns(@game)
      @association = Mongoid::Associations::ReferencesOne.new(@parent, options)
    end

    it "delegates to the proxied document" do
      @association.id.should == @game.id
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

    context "when the options have an extension" do

      before do
        @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person)
        @game = Game.new
        Game.expects(:first).returns(@game)
        @association = Mongoid::Associations::ReferencesOne.new(@parent, options)
      end

      it "adds the extension to the module" do
        @association.extension.should == "Testing"
      end

    end

  end

  describe ".instantiate" do

    it "delegates to new" do
      Mongoid::Associations::ReferencesOne.expects(:new).with(document, options, nil)
      Mongoid::Associations::ReferencesOne.new(document, options)
    end

  end

  describe "#method_missing" do

    before do
      @person = Person.new
      @game = stub
    end

    it "delegates to the document" do
      Game.expects(:first).with(:conditions => { "person_id"=> @person.id }).returns(@game)
      @game.expects(:strange_method)
      association = Mongoid::Associations::ReferencesOne.new(@person, options)
      association.strange_method
    end

  end

  describe "#nested_build" do

    before do
      @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person)
      @game = Game.new
      Game.expects(:first).returns(@game)
    end

    context "when attributes provided" do

      before do
        @association = Mongoid::Associations::ReferencesOne.new(@parent, options)
      end

      it "replaces the existing has_one" do
        game = @association.nested_build({ :score => 200 })
        game.score.should == 200
      end

    end

  end

  describe ".macro" do

    it "returns :references_one" do
      Mongoid::Associations::ReferencesOne.macro.should == :references_one
    end

  end

  describe "association value" do

    before do
      @person = Person.new
      @game = Game.new
      Game.expects(:first).with(:conditions => { "person_id"=> @person.id }).returns(nil)
    end

    it "delegates to the document" do
      association = Mongoid::Associations::ReferencesOne.new(@person, options)
      association.should == nil
    end

  end

  describe ".update" do

    before do
      @person = Person.new
      @game = Game.new
    end

    it "sets the parent on the child association" do
      @game.expects(:person=).with(@person)
      Mongoid::Associations::ReferencesOne.update(@game, @person, options)
    end

    it "returns the proxy" do
      @game.expects(:person=).with(@person)
      @proxy = Mongoid::Associations::ReferencesOne.update(@game, @person, options)
      @proxy.target.should == @game
    end

  end

end
