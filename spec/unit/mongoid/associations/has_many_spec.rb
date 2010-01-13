require "spec_helper"

describe Mongoid::Associations::HasMany do

  before do
    @attributes = { :addresses => [
      { :_id => "street-1", :street => "Street 1" },
      { :_id => "street-2", :street => "Street 2" } ] }
    @document = stub(:attributes => @attributes, :add_observer => true, :update => true)
  end

  describe "#[]" do

    before do
      @association = Mongoid::Associations::HasMany.new(@document, Mongoid::Associations::Options.new(:name => :addresses))
    end

    context "when the index is present in the association" do

      it "returns the document at the index" do
        @association[0].should be_a_kind_of(Address)
        @association[0].street.should == "Street 1"
      end

    end

    context "when the index is not present in the association" do

      it "returns nil" do
        @association[3].should be_nil
      end

    end

  end

  describe "#<<" do

    before do
      @association = Mongoid::Associations::HasMany.new(
        @document,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
      @address = Address.new
    end

    it "adds the parent document before appending to the array" do
      @association << @address
      @association.length.should == 3
      @address._parent.should == @document
    end

    it "allows multiple additions" do
      @association << @address
      @association << @address
      @association.length.should == 4
    end

  end

  describe "#build" do

    context "setting the parent relationship" do

      before do
        @person = Person.new
      end

      it "happens before any other operation" do
        address = @person.addresses.build(:set_parent => true, :street => "Madison Ave")
        address._parent.should == @person
        @person.addresses.first.should == address
      end

    end

    context "when a type is not provided" do

      before do
        @association = Mongoid::Associations::HasMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
      end

      it "adds a new document to the array with the suppied parameters" do
        @association.build({ :street => "Street 1" })
        @association.length.should == 3
        @association[2].should be_a_kind_of(Address)
        @association[2].street.should == "Street 1"
      end

      it "returns the newly built object in the association" do
        address = @association.build({ :street => "Yet Another" })
        address.should be_a_kind_of(Address)
        address.street.should == "Yet Another"
      end

    end

    context "when a type is provided" do

      before do
        @association = Mongoid::Associations::HasMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :shapes)
        )
      end

      it "instantiates a class of the type" do
        circle = @association.build({ :radius => 100 }, Circle)
        circle.should be_a_kind_of(Circle)
        circle.radius.should == 100
      end

    end

  end

  describe "#create" do

    context "when a type is not provided" do

      before do
        @association = Mongoid::Associations::HasMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
        @address = Address.new(:street => "Yet Another")
      end

      it "builds and saves a new object" do
        Mongoid::Commands::Save.expects(:execute).returns(true)
        address = @association.create({ :street => "Yet Another" })
        address.should be_a_kind_of(Address)
        address.street.should == "Yet Another"
      end

    end

    context "when a type is provided" do

      before do
        @association = Mongoid::Associations::HasMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :shapes)
        )
      end

      it "instantiates a class of that type" do
        Mongoid::Commands::Save.expects(:execute).returns(true)
        circle = @association.create({ :radius => 100 }, Circle)
        circle.should be_a_kind_of(Circle)
        circle.radius.should == 100
      end

    end

  end

  describe "#concat" do

    before do
      @association = Mongoid::Associations::HasMany.new(
        @document,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
      @address = Address.new
    end

    it "adds the parent document before appending to the array" do
      @association.concat [@address]
      @association.length.should == 3
      @address._parent.should == @document
    end

  end

  describe "#clear" do

    before do
      @association = Mongoid::Associations::HasMany.new(
        @document,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
      @address = Address.new
      @association << @address
    end

    it "clears out the association" do
      @association.clear
      @association.size.should == 0
    end

  end

  describe "#find" do

    before do
      @association = Mongoid::Associations::HasMany.new(@document, Mongoid::Associations::Options.new(:name => :addresses))
    end

    context "when finding all" do

      it "returns all the documents" do
        @association.find(:all).should == @association
      end

    end

    context "when finding by id" do

      it "returns the document in the array with that id" do
        address = @association.find("street-2")
        address.should_not be_nil
      end

    end

  end

  describe "#first" do

    context "when there are elements in the array" do

      before do
        @association = Mongoid::Associations::HasMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
      end

      it "returns the first element" do
        @association.first.should be_a_kind_of(Address)
        @association.first.street.should == "Street 1"
      end

    end

    context "when the array is empty" do

      before do
        @association = Mongoid::Associations::HasMany.new(
          Person.new,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
      end

      it "returns nil" do
        @association.first.should be_nil
      end

    end

  end

  describe "#initialize" do

    before do
      @canvas = stub(:attributes => { :shapes => [{ :_type => "Circle", :radius => 5 }] }, :update => true)
      @association = Mongoid::Associations::HasMany.new(
        @canvas,
        Mongoid::Associations::Options.new(:name => :shapes)
      )
    end

    it "creates the classes based on their types" do
      circle = @association.first
      circle.should be_a_kind_of(Circle)
      circle.radius.should == 5
    end

  end

  describe ".instantiate" do

    it "delegates to new" do
      Mongoid::Associations::HasMany.expects(:new).with(@document, @options)
      Mongoid::Associations::HasMany.instantiate(@document, @options)
    end

  end

  describe "#length" do

    context "#length" do

      it "returns the length of the delegated array" do
        @association = Mongoid::Associations::HasMany.new(
          @document,
          Mongoid::Associations::Options.new(:name => :addresses)
        )
        @association.length.should == 2
      end

    end

  end

  describe ".macro" do

    it "returns :has_many" do
      Mongoid::Associations::HasMany.macro.should == :has_many
    end

  end

  describe "#nested_build" do

    before do
      @association = Mongoid::Associations::HasMany.new(
        @document,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
    end

    it "returns the newly built object in the association" do
      @association.nested_build({ "0" => { :street => "Yet Another" } })
      @association.size.should == 3
      @association.last.street.should == "Yet Another"
    end

  end

  describe "#push" do

    before do
      @association = Mongoid::Associations::HasMany.new(
        @document,
        Mongoid::Associations::Options.new(:name => :addresses)
      )
      @address = Address.new
    end

    it "adds the parent document before appending to the array" do
      @association.push @address
      @association.length.should == 3
      @address._parent.should == @document
    end

    it "appends the document to the end of the array" do
      @association.push(Address.new)
      @association.length.should == 3
    end

  end

  describe ".update" do

    before do
      @address = Address.new(:street => "Madison Ave")
      @person = Person.new(:title => "Sir")
      Mongoid::Associations::HasMany.update([@address], @person, Mongoid::Associations::Options.new(:name => :addresses))
    end

    it "parentizes the child document" do
      @address._parent.should == @person
    end

    it "sets the attributes of the child on the parent" do
      @person.attributes[:addresses].should ==
        [{ "_id" => "madison-ave", "street" => "Madison Ave", "_type" => "Address" }]
    end

  end

end
