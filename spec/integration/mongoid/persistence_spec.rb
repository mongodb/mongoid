require "spec_helper"

describe Mongoid::Persistence do

  before do
    @person = Person.new(:title => "Sir", :ssn => "6969696", :pets => true)
  end

  after do
    @person.delete
  end

  describe ".create" do

    it "saves and returns the document" do
      person = Person.create(:title => "Sensei", :ssn => "666-66-6666")
      person.should be_a_kind_of(Person)
      person.should_not be_a_new_record
    end
  end

  describe ".create!" do

    context "inserting with a field that is not unique" do

      context "when a unique index exists" do

        after do
          Person.delete_all
        end

        it "raises an error" do
          Person.create!(:ssn => "555-55-9999")
          lambda { Person.create!(:ssn => "555-55-9999") }.should raise_error
        end
      end
    end
  end

  describe "#delete" do

    context "deleting a root document" do

      before do
        @person.save
      end

      it "deletes the document" do
        @person.delete
        lambda { Person.find(@person.id) }.should raise_error
      end

      it "returns true" do
        @person.delete.should be_true
      end
    end

    context "deleting an embedded document" do

      before do
        @address = Address.new(:street => "Bond Street")
        @person.addresses << @address
      end

      context "when the document is not yet saved" do

        it "removes the document from the parent" do
          @address.delete
          @person.addresses.should be_empty
          @person.attributes[:addresses].should be_empty
        end
      end

      context "when the document has been saved" do

        before do
          @address.save
        end

        it "removes the object from the parent and database" do
          @address.delete
          from_db = Person.find(@person.id)
          from_db.addresses.should be_empty
        end
      end
    end
  end

  describe "#destroy" do

    context "destroying a root document" do

      before do
        @person.save
      end

      it "destroys the document" do
        @person.destroy
        lambda { Person.find(@person.id) }.should raise_error
      end

      it "returns true" do
        @person.destroy.should be_true
      end
    end

    context "deleting an embedded document" do

      before do
        @address = Address.new(:street => "Bond Street", :city => "London", :country => "UK")
        @person.addresses << @address
      end

      context "when the document is not yet saved" do

        it "removes the document from the parent" do
          @address.delete
          @person.addresses.should be_empty
          @person.attributes[:addresses].should be_empty
        end
      end

      context "when the document has been saved" do

        before do
          @address.save
        end

        it "removes the object from the parent and database" do
          @address.delete
          from_db = Person.find(@person.id)
          from_db.addresses.should be_empty
        end
      end
    end

    context "deleting deeply embedded documents" do

      before do
        @address = Address.new(:street => "Bond Street", :city => "London", :country => "UK")
        @person.addresses << @address
      end

      context "when the document has been saved" do

        before do
          @address.save
          @location = Location.new(:name => "Home")
          @address.locations << @location
          @location.save
        end

        it "removes the object from the parent and database" do
          @location.delete
          from_db = Person.find(@person.id)
          from_db.addresses.first.locations.should be_empty
        end
      end
    end
  end

  describe "#save" do

    context "when validation passes" do

      it "returns true" do
        @person.save.should be_true
      end
    end

    context "when modifying the entire hierarchy" do

      before do
        @person = Person.create(:title => "Blah", :ssn => "244-01-1112")
        @person.title = "King"
        @person.addresses.build(:street => "Bond St")
        @person.create_name(:first_name => "Tony")
        @person.name.first_name = "Ryan"
      end

      after do
        Person.logger = nil
      end

      it "persists all changes in a single call" do
        Person.logger = Logger.new($stdout)
        @person.save
        @person.reload
        @person.title.should == "King"
        @person.name.first_name.should == "Ryan"
        @person.addresses.first.street.should == "Bond St"
      end
    end
  end

  describe "save!" do

    context "inserting with a field that is not unique" do

      context "when a unique index exists" do

        it "raises an error" do
          Person.create!(:ssn => "555-55-9999")
          person = Person.new(:ssn => "555-55-9999")
          lambda { person.save!(:ssn => "555-55-9999") }.should raise_error
        end
      end
    end
  end

  describe "#update_attributes" do

    before do
      @person.save
    end

    context "when validation passes" do

      it "returns true" do
        @person.update_attributes(:ssn => "555-55-1234").should be_true
      end

      it "saves the attributes" do
        @person.update_attributes(:ssn => "555-55-1235", :pets => false, :title => nil)
        @from_db = Person.find(@person.id)
        @from_db.ssn.should == "555-55-1235"
        @from_db.pets.should == false
        @from_db.title.should be_nil
      end
    end
  end

  describe "#delete_all" do

    before do
      @person.save
    end

    it "deletes all the documents" do
      Person.delete_all
      Person.count.should == 0
    end

    it "returns the number of documents deleted" do
      Person.delete_all.should == 1
    end
  end

  describe "#destroy_all" do

    before do
      @person.save
    end

    it "destroys all the documents" do
      Person.destroy_all
      Person.count.should == 0
    end

    it "returns the number of documents destroyed" do
      Person.destroy_all.should == 1
    end
  end
end
