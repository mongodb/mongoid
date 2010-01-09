require "spec_helper"

describe Mongoid::Document do

  before do
    Mongoid.database.collection(:people).drop
  end

  context "when document contains a hash field" do

    before do
      @map = { "first" => 10, "second" => "Blah" }
      @person = Person.create(:map => @map)
    end

    it "properly gets and sets the has attributes" do
      @person.map.should == @map
      @from_db = Person.find(@person.id)
      @from_db.map.should == @map
    end

  end

  describe ".collection" do

    context "on a subclass of a root document" do

      it "returns the root document collection" do
        Browser.collection.should == Canvas.collection
      end

    end

    context "on a namespaced document" do
      Medical::Patient.collection.name.should == "medical_patients"
    end

  end

  describe "#new" do

    it "gets a new or current database connection" do
      person = Person.new
      person.collection.should be_a_kind_of(Mongo::Collection)
    end

  end

  describe "#count" do

    before do
      5.times do |n|
        Person.create(:title => "Sir")
      end
    end

    it "returns the count" do
      Person.count.should == 5
    end

  end

  describe "#create" do

    it "persists a new record to the database" do
      person = Person.create(:title => "Test")
      person.id.should be_a_kind_of(String)
      person.attributes[:title].should == "Test"
    end

    context "when creating a has many" do

      before do
        @person = Person.new(:title => "Esquire")
        @person.addresses.create(:street => "Nan Jing Dong Lu", :city => "Shanghai")
      end

      it "should create and save the entire graph" do
        person = Person.find(@person.id)
        person.addresses.first.street.should == "Nan Jing Dong Lu"
      end

    end

  end

  context "chaining criteria scopes" do

    before do
      @one = Person.create(:title => "Mr", :age => 55, :terms => true)
      @two = Person.create(:title => "Sir", :age => 55, :terms => true)
      @three = Person.create(:title => "Sir", :age => 35, :terms => true)
      @four = Person.create(:title => "Sir", :age => 55, :terms => false)
    end

    it "finds by the merged criteria" do
      people = Person.old.accepted.knight
      people.count.should == 1
      people.first.should == @two
    end

  end

  context "#destroy" do

    context "on a root document" do

      before do
        @person = Person.create(:title => "Sir")
      end

      it "deletes the document" do
        @person.destroy
        lambda { Person.find(@person.id) }.should raise_error
      end

    end

    context "on an embedded document" do

      before do
        @person = Person.create(:title => "Lead")
        @person.addresses.create(:street => "1st Street")
        @person.create_name(:first_name => "Emmanuel")
        @person.save
      end

      it "deletes the document" do
        @person.addresses.first.destroy
        @person.name.should_not be_nil
        @person.name.destroy
        @person.addresses.first.should be_nil
        @person.name.should be_nil
      end

    end

  end

  context ".find_or_create_by" do

    before do
      @person = Person.create(:title => "Senior")
    end

    context "when the document is found" do

      it "returns the document" do
        Person.find_or_create_by(:title => "Senior").should == @person
      end

    end

    context "when the document is not found" do

      it "creates a new document" do
        person = Person.find_or_create_by(:title => "Senorita")
        person.title.should == "Senorita"
        person.should_not be_a_new_record
      end

    end

  end

  context ".find_or_initialize_by" do

    before do
      @person = Person.create(:title => "Senior")
    end

    context "when the document is found" do

      it "returns the document" do
        Person.find_or_initialize_by(:title => "Senior").should == @person
      end

    end

    context "when the document is not found" do

      it "returns a new document" do
        person = Person.find_or_initialize_by(:title => "Senorita")
        person.title.should == "Senorita"
        person.should be_a_new_record
      end

    end

  end

  describe "#find" do

    before do
      @person = Person.create(:title => "Test")
    end

    context "finding all documents" do

      it "returns an array of documents based on the selector provided" do
        documents = Person.find(:all, :conditions => { :title => "Test"})
        documents.first.title.should == "Test"
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
        person = Person.find(@person.id)
        person.id.should == @person.id
      end

    end

    context "limiting result fields" do

      it "adds the type field to the options" do
        people = Person.all(:fields => [ :title ])
        people.first.title.should == "Test"
      end

    end

  end

  describe "#group" do

    before do
      5.times do |num|
        Person.create(:title => "Sir", :age => num)
      end
    end

    it "returns grouped documents" do
      grouped = Person.only(:title).group
      people = grouped.first["group"]
      person = people.first
      person.should be_a_kind_of(Person)
      person.title.should == "Sir"
    end

  end

  context "when address is a has one" do

    before do
      @owner = PetOwner.create(:title => "AKC")
      @address = Address.new(:street => "Fido Street")
      @owner.address = @address
      @owner.save
    end

    after do
      PetOwner.delete_all
    end

    it "is a single object and not an array" do
      @from_db = PetOwner.find(@owner.id)
      @from_db.address.should == @address
    end

  end

  describe "#inspect" do

    before do
      @person = Person.new
    end

    it "returns a pretty string of class name and attributes" do
      attrs = Person.fields.map { |name, field| "#{name}: #{@person.attributes[name] || 'nil'}" } * ", "
      @person.inspect.should == "#<Person _id: #{@person.id}, #{attrs}>"
    end

  end

  describe "#paginate" do

    before do
      10.times do |num|
        Person.create(:title => "Test-#{num}")
      end
    end

    it "returns paginated documents" do
      Person.paginate(:per_page => 5, :page => 2).length.should == 5
    end

    it "returns a proper count" do
      @criteria = Mongoid::Criteria.translate(Person, { :per_page => 5, :page => 1 })
      @criteria.count.should == 10
    end

  end

  describe "#reload" do

    before do
      @person = Person.new(:title => "Sir")
      @person.save
      @from_db = Person.find(@person.id)
      @from_db.age = 35
      @from_db.save
    end

    it "reloads the obejct attributes from the db" do
      @person.reload
      @person.age.should == 35
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
        person = Person.find(@person.id)
        person.name.first_name.should == @name.first_name
      end

    end

    context "without validation" do

      before do
        @comment = Comment.new
      end

      it "always persists" do
        @comment.save(false).should be_true
        @from_db = Comment.find(@comment.id)
        @from_db.should == @comment
      end

    end

    context "with failing validation" do

      before do
        @comment = Comment.new
      end

      it "returns false" do
        @comment.should_not be_valid
      end

    end

  end

  context ".store_in" do

    after do
      Canvas.store_in(:canvases)
    end

    it "switches the database collection" do
      Canvas.collection.name.should == "canvases"
      Canvas.store_in(:browsers)
      Canvas.collection.name.should == "browsers"
    end

  end

  context "when has many exists through a has one" do

    before do
      @owner = PetOwner.new(:title => "Sir")
      @pet = Pet.new(:name => "Fido")
      @visit = VetVisit.new(:date => Date.today)
      @pet.vet_visits << @visit
      @owner.pet = @pet
    end

    it "can clear the association" do
      @owner.pet.vet_visits.size.should == 1
      @owner.pet.vet_visits.clear
      @owner.pet.vet_visits.size.should == 0
    end

  end

  context "the lot" do

    before do
      @person = Person.new(:title => "Sir")
      @name = Name.new(:first_name => "Syd", :last_name => "Vicious")
      @home = Address.new(:street => "Oxford Street")
      @business = Address.new(:street => "Upper Street")
      @person.name = @name
      @person.addresses << @home
      @person.addresses << @business
    end

    it "allows adding multiples on a has_many in a row" do
      @person.addresses.length.should == 2
    end

    context "when saving on a has_one" do

      before do
        @name.save
      end

      it "saves the entire graph up from the has_one" do
        person = Person.first(:conditions => { :title => "Sir" })
        person.should == @person
      end

    end

    context "when saving on a has_many" do

      before do
        @home.save
      end

      it "saves the entire graph up from the has_many" do
        person = Person.first(:conditions => { :title => "Sir" })
        person.should == @person
      end
    end

  end

  context "setting belongs_to" do

    before do
      @person = Person.new(:title => "Mr")
      @address = Address.new(:street => "Bloomsbury Ave")
      @person.save!
    end

    it "allows the parent reference to change" do
      @address.addressable = @person
      @address.save!
      @person.addresses.first.should == @address
    end

  end

  describe "#to_json" do

    before do
      @person = Person.new(:title => "Sir", :age => 30)
      @address = Address.new(:street => "Nan Jing Dong Lu")
      @person.addresses << @address
    end

    context "on a new document" do

      it "returns the json string" do
        @person.to_json.should == @person.attributes.to_json
      end

    end

    context "on a persisted document" do

      it "returns the json string" do
        @person.save
        from_db = Person.find(@person.id)
        from_db.to_json.should == from_db.attributes.to_json
      end

    end

  end

  context "typecasting" do

    before do
      @date = Date.new(1976, 7, 4)
      @person = Person.new(:dob => @date)
      @person.save
    end

    it "properly casts dates and times" do
      person = Person.first
      person.dob.should == @date
    end

  end

  context "versioning" do

    before do
      @comment = Comment.new(:text => "Testing")
      @comment.save
    end

    after do
      Comment.collection.drop
    end

    context "first save" do

      it "creates a new version" do
        @from_db = Comment.find(@comment.id)
        @from_db.text = "New"
        @from_db.save
        @from_db.versions.size.should == 1
        @from_db.version.should == 2
      end

    end

    context "multiple saves" do

      before do
        5.times do |n|
          @comment.save
        end
      end

      it "creates new versions" do
        @from_db = Comment.find(@comment.id)
        @from_db.version.should == 6
        @from_db.versions.size.should == 5
      end

    end

  end

  context "executing criteria with date comparisons" do

    context "handling specific dates" do

      before do
        @person = Person.create(:dob => Date.new(2000, 10, 31))
      end

      it "handles comparisons with todays date"do
        people = Person.where("this.dob < new Date()")
        people.first.should == @person
      end

      it "handles conparisons with a date range" do
        people = Person.where("new Date(1976, 10, 31) < this.dob && this.dob < new Date()")
        people.first.should == @person
      end

      it "handles false comparisons in a date range" do
        people = Person.where("new Date(2005, 10, 31) < this.dob && this.dob < new Date()")
        people.should be_empty
      end

      it "handles comparisons with date objects"do
        people = Person.where(:dob => { "$lt" => Date.today.midnight })
        people.first.should == @person
      end

    end

  end

end
