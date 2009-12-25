require "spec_helper"

describe Mongoid::Associations::BelongsToRelated do

  describe ".initialize" do

    context "when related id has been set" do

      before do
        @document = stub(:person_id => "5")
        @options = Mongoid::Associations::Options.new(:name => :person)
        @related = stub
      end

      it "finds the object by id" do
        Person.expects(:find).with(@document.person_id).returns(@related)
        association = Mongoid::Associations::BelongsToRelated.new(@document, "5", @options)
        association.should == @related
      end

    end

  end

  describe ".instantiate" do

    context "when foreign key is not nil" do

      before do
        @document = stub(:person_id => "5")
        @options = Mongoid::Associations::Options.new(:name => :person)
      end

      it "delegates to new" do
        Mongoid::Associations::BelongsToRelated.expects(:new).with(@document, "5", @options)
        Mongoid::Associations::BelongsToRelated.instantiate(@document, @options)
      end

    end

    context "when foreign key is nil" do

      before do
        @document = stub(:person_id => nil)
        @options = Mongoid::Associations::Options.new(:name => :person)
      end

      it "returns nil" do
        Mongoid::Associations::BelongsToRelated.instantiate(@document, @options).should be_nil
      end

    end

  end

  describe "#method_missing" do

    before do
      @person = Person.new(:title => "Mr")
      @document = stub(:person_id => "5")
      @options = Mongoid::Associations::Options.new(:name => :person)
      Person.expects(:find).with(@document.person_id).returns(@person)
      @association = Mongoid::Associations::BelongsToRelated.new(@document, "5", @options)
    end

    context "when getting values" do

      it "delegates to the document" do
        @association.title.should == "Mr"
      end

    end

    context "when setting values" do

      it "delegates to the document" do
        @association.title = "Sir"
        @association.title.should == "Sir"
      end

    end

  end

  describe ".macro" do

    it "returns :belongs_to_related" do
      Mongoid::Associations::BelongsToRelated.macro.should == :belongs_to_related
    end

  end

  describe ".update" do

    before do
      @related = stub(:id => "5")
      @child = Game.new
      @options = Mongoid::Associations::Options.new(:name => :person)
    end

    it "sets the related object id on the parent" do
      Mongoid::Associations::BelongsToRelated.update(@related, @child, @options)
      @child.person_id.should == "5"
    end

    it "returns the related object" do
      Mongoid::Associations::BelongsToRelated.update(@related, @child, @options).should == @related
    end

    context "when related is nil" do

      it "returns nil" do
        Mongoid::Associations::BelongsToRelated.update(nil, @child, @options).should be_nil
      end

    end

  end

end
