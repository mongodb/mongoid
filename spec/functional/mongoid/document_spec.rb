require "spec_helper"

describe Mongoid::Document do

  before do
    Person.delete_all
  end

  context "defining a BSON::ObjectId as a field" do

    let(:bson_id) do
      BSON::ObjectId.new
    end

    let(:person) do
      Person.new(:bson_id => bson_id)
    end

    before do
      person.save
    end

    it "persists the correct type" do
      person.reload.bson_id.should be_a(BSON::ObjectId)
    end

    it "has the correct value" do
      person.bson_id.should == bson_id
    end
  end

  context "when setting bson id fields to empty strings" do

    let(:post) do
      Post.new
    end

    before do
      post.person_id = ""
    end

    it "converts them to nil" do
      post.person_id.should be_nil
    end
  end

  context "creating anonymous documents" do

    context "when defining collection" do

      before do
        @model = Class.new do
          include Mongoid::Document
          store_in :anonymous
          field :gender
        end
      end

      it "allows the creation" do
        Object.const_set "Anonymous", @model
      end
    end
  end

  context "becoming another class" do

    before(:all) do
      class Manager < Person
        field :level, :type => Integer, :default => 1
      end
    end

    %w{upcasting downcasting}.each do |ctx|
      context ctx do
        before(:all) do
          if ctx == 'upcasting'
            @klass = Manager
            @to_become = Person
          else
            @klass = Person
            @to_become = Manager
          end
        end

        before(:each) do
          @obj = @klass.new(:title => 'Sir')
        end

        it "copies attributes" do
          became = @obj.becomes(@to_become)
          became.title.should == 'Sir'
        end

        it "copies state" do
          @obj.should be_new_record
          became = @obj.becomes(@to_become)
          became.should be_new_record

          @obj.save
          @obj.should_not be_new_record
          became = @obj.becomes(@to_become)
          became.should_not be_new_record

          @obj.destroy
          @obj.should be_destroyed
          became = @obj.becomes(@to_become)
          became.should be_destroyed
        end

        it "copies errors" do
          @obj.ssn = '$$$'
          @obj.should_not be_valid
          @obj.errors.should include(:ssn)
          became = @obj.becomes(@to_become)
          became.should_not be_valid
          became.errors.should include(:ssn)
        end

        it "sets the class type" do
          became = @obj.becomes(@to_become)
          became._type.should == @to_become.to_s
        end

        it "raises an error when inappropriate class is provided" do
          lambda {@obj.becomes(String)}.should raise_error(ArgumentError)
        end
      end
    end

    context "upcasting to class with default attributes" do

      it "applies default attributes" do
        @obj = Person.new(:title => 'Sir').becomes(Manager)
        @obj.level.should == 1
      end
    end
  end

  describe "#db" do

    it "returns the mongo database" do
      Person.db.should be_a(Mongo::DB)
    end
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
      person.collection.should be_a_kind_of(Mongoid::Collection)
    end
  end

  describe "#count" do

    before do
      5.times do |n|
        Person.create(:title => "Sir", :ssn => "#{n}")
      end
    end

    it "returns the count" do
      Person.count.should == 5
    end
  end

  describe "#create" do

    it "persists a new record to the database" do
      person = Person.create(:title => "Test")
      if Person.using_object_ids?
        person.id.should be_a_kind_of(BSON::ObjectId)
      else
        person.id.should be_a_kind_of(String)
      end
      person[:title].should == "Test"
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
      @one = Person.create(:title => "Mr", :age => 55, :terms => true, :ssn => "q")
      @two = Person.create(:title => "Sir", :age => 55, :terms => true, :ssn => "w")
      @three = Person.create(:title => "Sir", :age => 35, :terms => true, :ssn => "e")
      @four = Person.create(:title => "Sir", :age => 55, :terms => false, :ssn => "r")
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
        Mongoid.persist_in_safe_mode = true
      end

      after do
        Mongoid.persist_in_safe_mode = false
      end

      it "deletes the document" do
        @person.destroy
        lambda { Person.find(@person.id) }.should raise_error
      end

      it "marks the document as destroyed" do
        @person.should_not be_destroyed
        @person.destroy
        @person.should be_destroyed
      end
    end

    context "on an embedded document" do

      before do
        @person = Person.create(:title => "Lead")
        address = @person.addresses.create(:street => "1st Street")
        @person.create_name(:first_name => "Emmanuel")
        @person.save
      end

      it "deletes the document" do
        @person.addresses.first.destroy
        @person.name.should_not be_nil
        @person.name.destroy
        @person.addresses.should be_empty
        @person.name.should be_nil
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
        Person.create(:title => "Sir", :age => num, :ssn => num)
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
      @address.save
    end

    after do
      PetOwner.delete_all
    end

    it "is a single object and not an array" do
      @from_db = PetOwner.find(@owner.id)
      @from_db.address.should == @address
    end
  end

  describe "#reload" do

    let(:person) do
      Person.create(:ssn => "112-11-1121", :title => "Sir")
    end

    let!(:from_db) do
      Person.find(person.id).tap do |peep|
        peep.age = 35
        peep.save
      end
    end

    it "reloads the object attributes from the db" do
      person.reload
      person.age.should == 35
    end

    it "reload should return self" do
      person.reload.should == from_db
    end

    context "when an after initialize callback is defined" do

      let!(:book) do
        Book.create(:title => "Snow Crash")
      end

      before do
        book.update_attribute(:chapters, 50)
        book.reload
      end

      it "runs the callback" do
        book.chapters.should eq(5)
      end
    end

    context "when the document was dirty" do

      let(:person) do
        Person.create(:ssn => "543-24-2341")
      end

      before do
        person.title = "Sir"
        person.reload
      end

      it "resets the dirty modifications" do
        person.changes.should be_empty
      end
    end

    context "when document not saved" do

      context "when raising not found error" do

        it "raises an error" do
          lambda { Person.new.reload }.should raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end
    end

    context "when embedded documents change" do

      let!(:address) do
        person.addresses.create(:number => 27, :street => "Maiden Lane")
      end

      before do
        Person.collection.update(
          { "_id" => person.id }, { "$set" => { "addresses" => [] } }
        )
        person.reload
      end

      it "should reload the association" do
        person.addresses.should == []
      end
    end

    context "with relational associations" do

      context "for a references_one" do

        let!(:game) do
          person.create_game(:score => 50)
        end

        before do
          Game.collection.update(
            { "_id" => game.id }, { "$set" => { "score" => 75 } }
          )
          person.reload
        end

        it "reloads the association" do
          person.game.score.should == 75
        end
      end

      context "for a referenced_in" do

        let!(:game) do
          person.create_game(:score => 50)
        end

        before do
          Person.collection.update(
            { "_id" => person.id }, { "$set" => { "title" => "Mam" } }
          )
          game.reload
        end

        it "reloads the association" do
          game.person.title.should == "Mam"
        end
      end
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
        @comment.save(:validate => false).should be_true
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

    it "allows adding multiples on an embeds_many in a row" do
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

    context "when saving on an embeds_many" do

      before do
        @home.save
      end

      it "saves the entire graph up from the embeds_many" do
        person = Person.first(:conditions => { :title => "Sir" })
        person.should == @person
      end
    end
  end

  context "setting embedded_in" do

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
        @person.to_json.should include('"pets":false')
      end

      it "should return the id field correctly" do
        @person.to_json.should include('"_id":"'+@person.id.to_s+'"')
      end
    end

    context "on a persisted document" do
      before do
        @person.save
      end

      it "returns the json string" do
        from_db = Person.find(@person.id)
        from_db.to_json.should include('"pets":false')
      end

      it "should return the id field correctly" do
        @person.to_json.should include('"_id":"'+@person.id.to_s+'"')
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
      @comment = Comment.new(:title => 'Old', :text => "Testing")
      @comment.save
    end

    after do
      Comment.collection.drop
    end

    context "first save" do

      it "creates a new version" do
        @from_db = Comment.find(@comment.id)
        @from_db.title = "New"
        @from_db.save
        @from_db.versions.size.should == 1
        @from_db.version.should == 2
      end
    end

    context "multiple saves" do

      before do
        5.times do |n|
          @comment.update_attribute(:title, "#{n}")
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

  context "method with block" do

    before do
      @owner = Owner.create(:name => "Krzysiek")
    end

    after do
      Event.collection.drop
      User.collection.drop
    end

    context "called on a reference_many object" do
      before do
        {'My birthday' => Date.new(1981, 2, 1), 'My cat`s birthday' => Date.new(1981, 2, 1),
         'My pidgeon`s birthday' => Date.new(1981, 2, 2) }.each do |title, date|
          event = Event.new(:title => title, :date => date)
          event.owner = @owner
          event.save!
        end
      end

      let(:events) do
        rounds = []
        @owner.events.each_day(Date.new(1981, 1, 2), Date.new(1981, 2, 2)) do |date, collection|
          rounds << {:date => date, :collection => collection}
        end
        rounds.sort_by { |round| round[:date] }
      end

      it "should pass the block" do
        events.length.should == 2
        events.first[:collection].length.should == 2
        events.last[:collection].length.should == 1
      end
    end

    context "called on an embeds_many object" do
      before do
        {'My birthday' => Date.new(1981, 2, 1), 'My cat`s birthday' => Date.new(1981, 2, 1),
         'My pidgeon`s birthday' => Date.new(1981, 2, 2) }.each do |title, date|
          birthday = Birthday.new(:title => title, :date => date)
          birthday.owner = @owner
          birthday.save!
        end
      end

      let(:birthdays) do
        rounds = []
        @owner.birthdays.each_day(Date.new(1981, 1, 2), Date.new(1981, 2, 2)) do |date, collection|
          rounds << {:date => date, :collection => collection}
        end
        rounds.sort_by { |round| round[:date] }
      end

      it "should pass the block" do
        birthdays.length.should == 2
        birthdays.first[:collection].length.should == 2
        birthdays.last[:collection].length.should == 1
      end
    end
  end
end
