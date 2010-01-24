require "spec_helper"

describe Mongoid::Associations::BelongsTo do

  let(:child) { Name.new(:first_name => "Drexel", :last_name => "Spivey") }
  let(:target) { Person.new(:title => "Pimp") }

  let(:options) do
    Mongoid::Associations::Options.new(:name => :person)
  end

  describe "#find" do

    before do
      @association = Mongoid::Associations::BelongsTo.new(target, options)
    end

    context "when finding by id" do

      it "always returns the target document" do
        @association.find("").should == target
      end

    end

  end

  describe ".instantiate" do

    context "when parent exists" do

      before do
        @parent = stub
        @target = stub(:_parent => @parent)
        @association = Mongoid::Associations::BelongsTo.instantiate(@target, options)
      end

      it "sets the parent to the target" do
        @association.target.should == @parent
      end

    end

    context "when parent is nil" do

      before do
        @document = stub(:_parent => nil)
      end

      it "returns nil" do
        Mongoid::Associations::BelongsTo.instantiate(@document, options).should be_nil
      end

    end

  end

  describe ".macro" do

    it "returns :belongs_to" do
      Mongoid::Associations::BelongsTo.macro.should == :belongs_to
    end

  end

  describe "#method_missing" do

    before do
      @association = Mongoid::Associations::BelongsTo.new(target, options)
    end

    context "when method is a getter" do

      it "delegates to the target" do
        @association.title.should == "Pimp"
      end

    end

    context "when method is a setter" do

      before do
        @association.title = "Dealer"
      end

      it "delegates to the target" do
        @association.title.should == "Dealer"
      end

    end

    context "when method does not exist" do

      it "raises an error" do
        lambda { @association.nothing }.should raise_error(NoMethodError)
      end

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
