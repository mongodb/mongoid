require "spec_helper"

describe Mongoid::Associations::BelongsTo do

  describe "#find" do

    before do
      @parent = Name.new(:first_name => "Drexel")
      @options = Mongoid::Associations::Options.new(:name => :person)
      @association = Mongoid::Associations::BelongsTo.new(@parent, @options)
    end

    context "when finding by id" do

      it "returns the document in the array with that id" do
        name = @association.find(Mongo::ObjectID.new.to_s)
        name.should == @parent
      end

    end

  end

  context "when decorating" do

    before do
      @parent = Name.new(:first_name => "Drexel")
      @options = Mongoid::Associations::Options.new(:name => :person)
      @association = Mongoid::Associations::BelongsTo.new(@parent, @options)
    end

    context "when getting values" do

      it "delegates to the document" do
        @association.first_name.should == "Drexel"
      end

    end

    context "when setting values" do

      it "delegates to the document" do
        @association.first_name = "Test"
        @association.first_name.should == "Test"
      end

    end

  end

  describe ".instantiate" do

    context "when parent exists" do

      before do
        @parent = Name.new(:first_name => "Drexel")
        @document = stub(:_parent => @parent)
        @options = Mongoid::Associations::Options.new(:name => :person)
      end

      it "delegates to new" do
        Mongoid::Associations::BelongsTo.expects(:new).with(@parent, @options)
        Mongoid::Associations::BelongsTo.instantiate(@document, @options)
      end

    end

    context "when parent is nil" do

      before do
        @document = stub(:_parent => nil)
        @options = Mongoid::Associations::Options.new(:name => :person)
      end

      it "returns nil" do
        Mongoid::Associations::BelongsTo.instantiate(@document, @options).should be_nil
      end

    end

  end

  describe ".macro" do

    it "returns :belongs_to" do
      Mongoid::Associations::BelongsTo.macro.should == :belongs_to
    end

  end

  describe ".update" do

    context "when child is a has one" do

      before do
        @name = Name.new(:first_name => "Test", :last_name => "User")
        @person = Person.new(:title => "Mrs")
        @options = Mongoid::Associations::Options.new(:name => :person, :inverse_of => :name)
        Mongoid::Associations::BelongsTo.update(@person, @name, @options)
      end

      it "updates the parent document" do
        @person.name.should == @name
        @person.attributes[:name].except(:_id).should ==
          { "first_name" => "Test", "last_name" => "User", "_type" => "Name" }
      end

    end

    context "when child is a has many" do

      before do
        @address = Address.new(:street => "Broadway")
        @person = Person.new(:title => "Mrs")
        @options = Mongoid::Associations::Options.new(:name => :person, :inverse_of => :addresses)
        Mongoid::Associations::BelongsTo.update(@person, @address, @options)
      end

      it "updates the parent document" do
        @person.addresses.first.should == @address
      end

    end

  end

end
