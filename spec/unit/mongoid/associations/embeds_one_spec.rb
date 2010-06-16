require "spec_helper"

describe Mongoid::Associations::EmbedsOne do

  before do
    @attributes = { "mixed_drink" => {
      "name" => "Jack and Coke", "_type" => "MixedDrink" },
      "writer" => { "speed" => 50, "_type" => "HtmlWriter" }
    }
    @document = stub(:raw_attributes => @attributes, :observe => true)
  end

  describe "#build_*" do

    context "when attributes provided" do

      before do
        @association = Mongoid::Associations::EmbedsOne.new(
          @document,
          @attributes["mixed_drink"],
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
        @association = Mongoid::Associations::EmbedsOne.new(
          @document,
          @attributes["writer"],
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
        name = @person.build_name(:set_parent => true, :first_name => "Steve")
        name._parent.should == @person
        @person.name.should == name
      end

    end

  end

  describe "#initialize" do

    before do
      @parent = Person.new(:title => "Dr")
      @name = Name.new(:first_name => "Richard", :last_name => "Dawkins")
      @parent.name = @name
      @block = Proc.new {
        def extension
          "Testing"
        end
      }
      @options = Mongoid::Associations::Options.new(:name => :name, :extend => @block)
      @association = Mongoid::Associations::EmbedsOne.new(@parent, {}, @options)
    end

    context "when the options have an extension" do

      it "adds the extension module" do
        @association.extension.should == "Testing"
      end

    end

  end

  describe ".instantiate" do

    context "when the attributes are nil" do

      before do
        @document = Person.new
        @association = Mongoid::Associations::EmbedsOne.instantiate(
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
        @document = stub(:raw_attributes => { "name" => {} })
        @association = Mongoid::Associations::EmbedsOne.instantiate(
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
        @document = stub(:raw_attributes => { "name" => { "first_name" => "Test" } })
        @options = Mongoid::Associations::Options.new(:name => :name)
      end

      it "delegates to new" do
        Mongoid::Associations::EmbedsOne.expects(:new).with(
          @document,
          { "first_name" => "Test" },
          @options,
          nil
        )
        Mongoid::Associations::EmbedsOne.instantiate(@document, @options)
      end

    end

  end

  describe "#method_missing" do

    before do
      @association = Mongoid::Associations::EmbedsOne.new(
        @document,
        @attributes["mixed_drink"],
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
        @association = Mongoid::Associations::EmbedsOne.new(
          @document,
          @attributes["mixed_drink"],
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

    it "returns :embeds_one" do
      Mongoid::Associations::EmbedsOne.macro.should == :embeds_one
    end

  end

  describe ".update" do

    context "when setting to a non-nil value" do

      before do
        @name = Name.new(:first_name => "Donald")
        @person = Person.new(:title => "Sir")
        @association = Mongoid::Associations::EmbedsOne.update(
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
          { "_id" => "donald", "first_name" => "Donald" }
      end

      it "returns the proxy" do
        @association.target.should == @name
      end

    end

    context "when setting the object to nil" do

      before do
        @name = Name.new(:first_name => "Donald")
        @person = Person.new(:title => "Sir")
        Mongoid::Associations::EmbedsOne.update(
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

  describe "#to_a" do

    before do
      @association = Mongoid::Associations::EmbedsOne.new(
        @document,
        @attributes["mixed_drink"],
        Mongoid::Associations::Options.new(:name => :mixed_drink)
      )
    end

    it "returns the target in a new array" do
      @association.to_a.first.should be_a_kind_of(MixedDrink)
    end

  end

  describe "#valid?" do

    context "when the document is not nil" do

      before do
        @document = stub(:raw_attributes => { "name" => { "first_name" => "Test" } }, :observe => true)
        @options = Mongoid::Associations::Options.new(:name => :name)
        @association = Mongoid::Associations::EmbedsOne.instantiate(@document, @options)
      end

      it "validates the document" do
        @association.valid?.should be_true
      end

    end

  end

end
