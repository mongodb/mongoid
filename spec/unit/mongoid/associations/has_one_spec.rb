require "spec_helper"

describe Mongoid::Associations::HasOne do

  before do
    @attributes = { :mixed_drink => { :name => "Jack and Coke" } }
    @document = stub(:attributes => @attributes, :update => true)
  end

  describe "#build" do

    context "when attributes provided" do

      before do
        @association = Mongoid::Associations::HasOne.new(
          @document,
          @attributes[:mixed_drink],
          Mongoid::Associations::Options.new(:name => :mixed_drink)
        )
      end

      it "replaces the existing has_one" do
        drink = @association.build({ :name => "Sapphire and Tonic" })
        drink.name.should == "Sapphire and Tonic"
      end

    end

  end

  describe "#create" do

    context "when attributes provided" do

      before do
        @association = Mongoid::Associations::HasOne.new(
          @document,
          @attributes[:mixed_drink],
          Mongoid::Associations::Options.new(:name => :mixed_drink)
        )
        @drink = MixedDrink.new(:name => "Sapphire and Tonic")
      end

      it "replaces and saves the existing has_one" do
        Mongoid::Commands::Create.expects(:execute).returns(@drink)
        drink = @association.create({ :name => "Sapphire and Tonic" })
        drink.name.should == "Sapphire and Tonic"
      end

    end

  end

  describe "#method_missing" do

    before do
      @association = Mongoid::Associations::HasOne.new(
        @document,
        @attributes[:mixed_drink],
        Mongoid::Associations::Options.new(:name => :mixed_drink)
      )
    end

    context "when getting values" do

      it "delegates to the document" do
        @association.name.should == "Jack and Coke"
      end

    end

    context "when setting values" do

      it "delegates to the document" do
        @association.name = "Jack and Coke"
        @association.name.should == "Jack and Coke"
      end

    end

  end

  describe ".instantiate" do

    context "when attributes exist" do

      before do
        @document = stub(:attributes => { :name => { :first_name => "Test" } })
        @options = Mongoid::Associations::Options.new(:name => :name)
      end

      it "delegates to new" do
        Mongoid::Associations::HasOne.expects(:new).with(@document, { :first_name => "Test" }, @options)
        Mongoid::Associations::HasOne.instantiate(@document, @options)
      end

    end

  end

  describe ".macro" do

    it "returns :has_one" do
      Mongoid::Associations::HasOne.macro.should == :has_one
    end

  end

  describe ".update" do

    before do
      @name = Name.new(:first_name => "Donald")
      @person = Person.new(:title => "Sir")
      Mongoid::Associations::HasOne.update(
        @name,
        @person,
        Mongoid::Associations::Options.new(:name => :name)
      )
    end

    it "parentizes the child document" do
      @name.parent.should == @person
    end

    it "sets the attributes of the child on the parent" do
      @person.attributes[:name].should ==
        { "_id" => "donald", "first_name" => "Donald" }
    end

  end

end
