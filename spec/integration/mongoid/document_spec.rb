require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoid::Document do

  before do
    Mongoid.database.collection(:people).drop
  end

  describe "#new" do

    it "gets a new or current database connection" do
      person = Person.new
      person.collection.should be_a_kind_of(Mongo::Collection)
    end

  end

  describe "#create" do

    it "persists a new record to the database" do
      person = Person.create(:test => "Test")
      person.id.should be_a_kind_of(Mongo::ObjectID)
      person.attributes[:test].should == "Test"
    end

  end

  describe "#find" do

    before do
      @person = Person.create(:title => "Test", :document_class => "Person")
    end

    context "finding all documents" do

      it "returns an array of documents based on the selector provided" do
        documents = Person.find(:all, :conditions => { :title => "Test"})
        documents[0].title.should == "Test"
      end

    end

    context "finding first document" do

      it "returns the first document based on the selector provided" do
        person = Person.find(:first, :conditions => { :title => "Test" })
        person.title.should == "Test"
      end

    end

    context "finding by id" do

      it "finds the document by the supplied id" do
        person = Person.find(@person.id.to_s)
        person.id.should == @person.id
      end

    end

  end

  describe "#group_by" do

    before do
      30.times do |num|
        Person.create(:title => "Sir", :age => num, :document_class => "Person")
      end
    end

    it "returns grouped documents" do
      grouped = Person.group_by([:title], {})
      people = grouped.first["group"]
      person = people.first
      person.should be_a_kind_of(Person)
      person.title.should == "Sir"
    end

  end

  describe "#paginate" do

    before do
      30.times do |num|
        Person.create(:title => "Test-#{num}", :document_class => "Person")
      end
    end

    it "returns paginated documents" do
      Person.paginate(:per_page => 20, :page => 2).length.should == 10
    end

  end

  describe "#save" do

    context "on a has_one association" do

      before do
        @person = Person.new(:title => "Sir")
        @name = Name.new(:first_name => "Test")
        @person.name = @name
      end

      it "saves the parent document" do
        @name.save
        person = Person.find(@person.id.to_s)
        person.name.first_name.should == @name.first_name
      end

    end

  end

end
