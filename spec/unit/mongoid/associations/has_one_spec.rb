require "spec_helper"

describe Mongoid::Associations::HasOne do

  before do
    @attributes = { :mixed_drink => {
      :name => "Jack and Coke", :_type => "MixedDrink" },
      :writer => { :speed => 50, :_type => "HtmlWriter" }
    }
    @document = stub(:attributes => @attributes, :update => true)
  end

  describe "#build_*" do

    context "when attributes provided" do

      before do
        @association = Mongoid::Associations::HasOne.new(
          @document,
          @attributes[:mixed_drink],
          Mongoid::Associations::Options.new(:name => :mixed_drink)
        )
      end

      it "replaces the existing has_one" do
        drink = @association.send(:build, { :name => "Sapphire and Tonic" })
        drink.name.should == "Sapphire and Tonic"
      end

    end

    context "when a type is supplied" do

      before do
        @association = Mongoid::Associations::HasOne.new(
          @document,
          @attributes[:writer],
          Mongoid::Associations::Options.new(:name => :writer)
        )
      end

      it "instantiates a class of that type" do
        writer = @association.send(:build, { :speed => 500 }, HtmlWriter)
        writer.should be_a_kind_of(HtmlWriter)
        writer.speed.should == 500
      end

    end

    context "setting the parent relationship" do

      before do
        @person = Person.new
      end

      it "happens before any other operation" do
        name = @person.build_name(:set_parent => true, :street => "Madison Ave")
        name._parent.should == @person
        @person.name.should == name
      end

    end

  end

  describe ".instantiate" do

    context "when the attributes are nil" do

      before do
        @document = Person.new
        @association = Mongoid::Associations::HasOne.instantiate(
          @document,
          Mongoid::Associations::Options.new(:name => :name)
        )
      end

      it "returns nil" do
        @association.should be_nil
      end

    end

    context "when attributes are empty" do

      before do
        @document = stub(:attributes => { :name => {} })
        @association = Mongoid::Associations::HasOne.instantiate(
          @document,
          Mongoid::Associations::Options.new(:name => :name)
        )
      end

      it "returns nil" do
        @association.should be_nil
      end

    end

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

  describe "#nested_build" do

    context "when attributes provided" do

      before do
        @association = Mongoid::Associations::HasOne.new(
          @document,
          @attributes[:mixed_drink],
          Mongoid::Associations::Options.new(:name => :mixed_drink)
        )
      end

      it "replaces the existing has_one" do
        drink = @association.nested_build({ :name => "Sapphire and Tonic" })
        drink.name.should == "Sapphire and Tonic"
      end

    end

  end

  describe ".macro" do

    it "returns :has_one" do
      Mongoid::Associations::HasOne.macro.should == :has_one
    end

  end

  describe ".update" do

    context "when setting to a non-nil value" do

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
        @name._parent.should == @person
      end

      it "sets the attributes of the child on the parent" do
        @person.attributes[:name].should ==
          { "_id" => "donald", "first_name" => "Donald", "_type" => "Name" }
      end

    end

    context "when setting the object to nil" do

      before do
        @name = Name.new(:first_name => "Donald")
        @person = Person.new(:title => "Sir")
        Mongoid::Associations::HasOne.update(
          nil,
          @person,
          Mongoid::Associations::Options.new(:name => :name)
        )
      end

      it "clears out the association" do
        @person.name.should be_nil
      end

    end

  end

  describe "#valid?" do

    context "when the document is not nil" do

      before do
        @document = stub(:attributes => { :name => { :first_name => "Test" } }, :update => true)
        @options = Mongoid::Associations::Options.new(:name => :name)
        @association = Mongoid::Associations::HasOne.instantiate(@document, @options)
      end

      it "validates the document" do
        @association.valid?.should be_true
      end

    end

  end

end
