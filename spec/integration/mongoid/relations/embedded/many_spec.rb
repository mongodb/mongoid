require "spec_helper"

describe Mongoid::Relations::Embedded::Many do

  [ :<<, :push, :concat ].each do |method|

    describe "#{method}" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:address) do
          Address.new
        end

        before do
          person.addresses.send(method, address)
        end

        it "appends to the target" do
          person.addresses.should == [ address ]
        end

        it "sets the base on the inverse relation" do
          address.addressable.should == person
        end

        it "does not save the new document" do
          address.should_not be_persisted
        end

        it "sets the parent on the child" do
          address._parent.should == person
        end

        it "sets the metadata on the child" do
          address.metadata.should_not be_nil
        end

        it "sets the index on the child" do
          address._index.should == 0
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create(:ssn => "234-44-4432")
        end

        let(:address) do
          Address.new
        end

        before do
          person.addresses.send(method, address)
        end

        it "saves the new document" do
          address.should be_persisted
        end
      end
    end
  end

  describe "#=" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let(:address) do
        Address.new
      end

      before do
        person.addresses = [ address ]
      end

      it "sets the target of the relation" do
        person.addresses.should == [ address ]
      end

      it "sets the base on the inverse relation" do
        address.addressable.should == person
      end

      it "does not save the target" do
        address.should_not be_persisted
      end

      it "sets the parent on the child" do
        address._parent.should == person
      end

      it "sets the metadata on the child" do
        address.metadata.should_not be_nil
      end

      it "sets the index on the child" do
        address._index.should == 0
      end
    end

    context "when the parent is not a new record" do

      let(:person) do
        Person.create(:ssn => "999-98-9988")
      end

      let(:address) do
        Address.new
      end

      before do
        person.addresses = [ address ]
      end

      it "saves the target" do
        address.should be_persisted
      end
    end
  end

  describe "#= nil" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let(:address) do
        Address.new
      end

      before do
        person.addresses = [ address ]
        person.addresses = nil
      end

      it "sets the relation to empty" do
        person.addresses.should be_empty
      end

      it "removes the inverse relation" do
        address.addressable.should be_nil
      end
    end

    context "when the inverse is already nil" do

      let(:person) do
        Person.new
      end

      before do
        person.addresses = nil
      end

      it "sets the relation to empty" do
        person.addresses.should be_empty
      end
    end

    context "when the documents are not new records" do

      let(:person) do
        Person.create(:ssn => "437-11-1112")
      end

      let(:address) do
        Address.new
      end

      before do
        person.addresses = [ address ]
        person.addresses = nil
      end

      it "sets the relation to empty" do
        person.addresses.should be_empty
      end

      it "removed the inverse relation" do
        address.addressable.should be_nil
      end

      it "deletes the child document" do
        address.should be_destroyed
      end
    end
  end

  describe "#build" do

    let(:person) do
      Person.new
    end

    let(:address) do
      person.addresses.build(:street => "Bond")
    end

    it "appends to the target" do
      person.addresses.should == [ address ]
    end

    it "sets the base on the inverse relation" do
      address.addressable.should == person
    end

    it "does not save the new document" do
      address.should_not be_persisted
    end

    it "sets the parent on the child" do
      address._parent.should == person
    end

    it "sets the metadata on the child" do
      address.metadata.should_not be_nil
    end

    it "sets the index on the child" do
      address._index.should == 0
    end

    it "writes to the attributes" do
      address.street.should == "Bond"
    end
  end

  describe "#count" do

    let(:person) do
      Person.new
    end

    before do
      person.addresses.create(:street => "Upper")
      person.addresses.build(:street => "Bond")
    end

    it "returns the number of persisted documents" do
      person.addresses.count.should == 1
    end
  end

  describe "#create" do

    let(:person) do
      Person.new
    end

    let(:address) do
      person.addresses.create(:street => "Bond")
    end

    it "appends to the target" do
      person.addresses.should == [ address ]
    end

    it "sets the base on the inverse relation" do
      address.addressable.should == person
    end

    it "saves the document" do
      address.should be_persisted
    end

    it "sets the parent on the child" do
      address._parent.should == person
    end

    it "sets the metadata on the child" do
      address.metadata.should_not be_nil
    end

    it "sets the index on the child" do
      address._index.should == 0
    end

    it "writes to the attributes" do
      address.street.should == "Bond"
    end
  end

  describe "#create!" do

    let(:person) do
      Person.new
    end

    context "when validation passes" do

      let(:address) do
        person.addresses.create!(:street => "Bond")
      end

      it "appends to the target" do
        person.addresses.should == [ address ]
      end

      it "sets the base on the inverse relation" do
        address.addressable.should == person
      end

      it "saves the document" do
        address.should be_persisted
      end

      it "sets the parent on the child" do
        address._parent.should == person
      end

      it "sets the metadata on the child" do
        address.metadata.should_not be_nil
      end

      it "sets the index on the child" do
        address._index.should == 0
      end

      it "writes to the attributes" do
        address.street.should == "Bond"
      end
    end

    context "when validation fails" do

      it "raises an error" do
        expect {
          person.addresses.create!(:street => "1")
        }.to raise_error(Mongoid::Errors::Validations)
      end
    end
  end

  describe "#delete" do

    let(:person) do
      Person.new
    end

    let(:address_one) do
      Address.new
    end

    let(:address_two) do
      Address.new
    end

    before do
      person.addresses << [ address_one, address_two ]
    end

    context "when the document exists in the relation" do

      before do
        @deleted = person.addresses.delete(address_one)
      end

      it "deletes the document" do
        person.addresses.should == [ address_two ]
      end

      it "reindexes the relation" do
        address_two._index.should == 0
      end

      it "returns the document" do
        @deleted.should == address_one
      end
    end

    context "when the document does not exist" do

      it "returns nil" do
        person.addresses.delete(Address.new).should be_nil
      end
    end
  end

  [ :delete_all, :destroy_all ].each do |method|

    describe "##{method}" do

      let(:person) do
        Person.create(:ssn => "112-33-4432")
      end

      context "when the documents are new" do

        let!(:address_one) do
          person.addresses.build(:street => "Bond")
        end

        let!(:address_two) do
          person.addresses.build(:street => "Upper")
        end

        context "when conditions are provided" do

          before do
            @deleted = person.addresses.send(
              method,
              :conditions => { :street => "Bond" }
            )
          end

          it "removes the matching documents" do
            person.addresses.size.should == 1
          end

          it "returns the number deleted" do
            @deleted.should == 1
          end
        end

        context "when conditions are not provided" do

          before do
            @deleted = person.addresses.send(method)
          end

          it "removes all documents" do
            person.addresses.size.should == 0
          end

          it "returns the number deleted" do
            @deleted.should == 2
          end
        end
      end

      context "when the documents persisted" do

        let!(:address_one) do
          person.addresses.create(:street => "Bond")
        end

        let!(:address_two) do
          person.addresses.create(:street => "Upper")
        end

        context "when conditions are provided" do

          before do
            @deleted = person.addresses.send(
              method,
              :conditions => { :street => "Bond" }
            )
          end

          it "deletes the matching documents from the db" do
            person.addresses.count.should == 1
          end

          it "returns the number deleted" do
            @deleted.should == 1
          end
        end

        context "when conditions are not provided" do

          before do
            @deleted = person.addresses.send(method)
          end

          it "deletes all the documents from the db" do
            person.addresses.count.should == 0
          end

          it "returns the number deleted" do
            @deleted.should == 2
          end
        end
      end
    end
  end

  describe "#find" do

    let(:person) do
      Person.new
    end

    let!(:address_one) do
      person.addresses.build(:street => "Bond", :city => "London")
    end

    let!(:address_two) do
      person.addresses.build(:street => "Upper", :city => "London")
    end

    context "when providing an id" do

      context "when the id matches" do

        let(:address) do
          person.addresses.find(address_one.id)
        end

        it "returns the matching document" do
          address.should == address_one
        end
      end

      context "when the id does not match" do

        context "when config set to raise error" do

          before do
            Mongoid.raise_not_found_error = true
          end

          after do
            Mongoid.raise_not_found_error = false
          end

          it "raises an error" do
            expect {
              person.addresses.find(BSON::ObjectId.new)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when config set not to raise error" do

          let(:address) do
            person.addresses.find(BSON::ObjectId.new)
          end

          before do
            Mongoid.raise_not_found_error = false
          end

          it "returns nil" do
            address.should be_nil
          end
        end
      end
    end

    context "when providing an array of ids" do

      context "when the ids match" do

        let(:addresses) do
          person.addresses.find([ address_one.id, address_two.id ])
        end

        it "returns the matching documents" do
          addresses.should == [ address_one, address_two ]
        end
      end

      context "when the ids do not match" do

        context "when config set to raise error" do

          before do
            Mongoid.raise_not_found_error = true
          end

          after do
            Mongoid.raise_not_found_error = false
          end

          it "raises an error" do
            expect {
              person.addresses.find([ BSON::ObjectId.new ])
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when config set not to raise error" do

          let(:addresses) do
            person.addresses.find([ BSON::ObjectId.new ])
          end

          before do
            Mongoid.raise_not_found_error = false
          end

          it "returns an empty array" do
            addresses.should be_empty
          end
        end
      end
    end

    context "when finding first" do

      context "when there is a match" do

        let(:address) do
          person.addresses.find(:first, :conditions => { :city => "London" })
        end

        it "returns the first matching document" do
          address.should == address_one
        end
      end

      context "when there is no match" do

        let(:address) do
          person.addresses.find(:first, :conditions => { :city => "Praha" })
        end

        it "returns nil" do
          address.should be_nil
        end
      end
    end

    context "when finding last" do

      context "when there is a match" do

        let(:address) do
          person.addresses.find(:last, :conditions => { :city => "London" })
        end

        it "returns the last matching document" do
          address.should == address_two
        end
      end

      context "when there is no match" do

        let(:address) do
          person.addresses.find(:last, :conditions => { :city => "Praha" })
        end

        it "returns nil" do
          address.should be_nil
        end
      end
    end

    context "when finding all" do

      context "when there is a match" do

        let(:addresses) do
          person.addresses.find(:all, :conditions => { :city => "London" })
        end

        it "returns the matching documents" do
          addresses.should == [ address_one, address_two ]
        end
      end

      context "when there is no match" do

        let(:address) do
          person.addresses.find(:all, :conditions => { :city => "Praha" })
        end

        it "returns an empty array" do
          address.should be_empty
        end
      end
    end
  end

  describe "#find_or_create_by" do

    let(:person) do
      Person.new
    end

    let!(:address) do
      person.addresses.build(:street => "Bourke", :city => "Melbourne")
    end

    context "when the document exists" do

      let(:found) do
        person.addresses.find_or_create_by(:street => "Bourke")
      end

      it "returns the document" do
        found.should == address
      end
    end

    context "when the document does not exist" do

      let(:found) do
        person.addresses.find_or_create_by(:street => "King")
      end

      it "sets the new document attributes" do
        found.street.should == "King"
      end

      it "returns a newly persisted document" do
        found.should be_persisted
      end
    end
  end

  describe "#find_or_initialize_by" do

    let(:person) do
      Person.new
    end

    let!(:address) do
      person.addresses.build(:street => "Bourke", :city => "Melbourne")
    end

    context "when the document exists" do

      let(:found) do
        person.addresses.find_or_initialize_by(:street => "Bourke")
      end

      it "returns the document" do
        found.should == address
      end
    end

    context "when the document does not exist" do

      let(:found) do
        person.addresses.find_or_initialize_by(:street => "King")
      end

      it "sets the new document attributes" do
        found.street.should == "King"
      end

      it "returns a non persisted document" do
        found.should_not be_persisted
      end
    end
  end

  describe "#paginate" do

    let(:person) do
      Person.new
    end

    before do
      4.times do |n|
        person.addresses.build(:street => "#{n} Bond St", :city => "London")
      end
    end

    context "when provided page and per page options" do

      let(:addresses) do
        person.addresses.paginate(:page => 2, :per_page => 2)
      end

      it "returns the correct number of documents" do
        addresses.size.should == 2
      end

      it "returns the supplied page of documents" do
        addresses[0].street.should == "2 Bond St"
        addresses[1].street.should == "3 Bond St"
      end
    end
  end
end
