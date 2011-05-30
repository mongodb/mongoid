require "spec_helper"

describe Mongoid::Relations::Embedded::Many do

  before do
    [ Person, Account, Quiz, Role ].map(&:delete_all)
  end

  context "when validating the parent before accessing the child" do

    let!(:account) do
      Account.new(:name => "Testing").tap do |acct|
        acct.memberships.build
        acct.save
      end
    end

    let(:from_db) do
      Account.first
    end

    context "when saving" do

      before do
        account.name = ""
        account.save
      end

      it "does not lose the parent reference" do
        from_db.memberships.first.account.should == account
      end
    end

    context "when updating attributes" do

      before do
        from_db.update_attributes(:name => "")
      end

      it "does not lose the parent reference" do
        from_db.memberships.first.account.should == account
      end
    end
  end

  [ :<<, :push, :concat ].each do |method|

    describe "##{method}" do

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

        it "sets the same instance on the inverse relation" do
          address.addressable.should eql(person)
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

      context "when appending more than one document at once" do

        let(:person) do
          Person.create(:ssn => "234-44-4432")
        end

        let(:address_one) do
          Address.new
        end

        let(:address_two) do
          Address.new
        end

        before do
          person.addresses.send(method, [ address_one, address_two ])
        end

        it "saves the first document" do
          address_one.should be_persisted
        end

        it "saves the second document" do
          address_two.should be_persisted
        end
      end

      context "when the parent and child have a cyclic relation" do

        context "when the parent is a new record" do

          let(:parent_role) do
            Role.new
          end

          let(:child_role) do
            Role.new
          end

          before do
            parent_role.child_roles.send(method, child_role)
          end

          it "appends to the target" do
            parent_role.child_roles.should == [ child_role ]
          end

          it "sets the base on the inverse relation" do
            child_role.parent_role.should == parent_role
          end

          it "sets the same instance on the inverse relation" do
            child_role.parent_role.should eql(parent_role)
          end

          it "does not save the new document" do
            child_role.should_not be_persisted
          end

          it "sets the parent on the child" do
            child_role._parent.should == parent_role
          end

          it "sets the metadata on the child" do
            child_role.metadata.should_not be_nil
          end

          it "sets the index on the child" do
            child_role._index.should == 0
          end
        end

        context "when the parent is not a new record" do

          let(:parent_role) do
            Role.create(:name => "CEO")
          end

          let(:child_role) do
            Role.new(:name => "COO")
          end

          before do
            parent_role.child_roles.send(method, child_role)
          end

          it "saves the new document" do
            child_role.should be_persisted
          end
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

      it "sets the same instance on the inverse relation" do
        address.addressable.should eql(person)
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

    context "when replacing an existing relation" do

      let(:person) do
        Person.create(:ssn => "999-98-9988", :addresses => [
          Address.new(:street => "1st St"),
          Address.new(:street => "2nd St")
        ])
      end

      let(:address) do
        Address.new(:street => "3rd St")
      end

      before do
        person.addresses = [ address ]
      end

      it "deletes the old documents" do
        person.reload.addresses.should == [ address ]
      end
    end

    context "when the relation has an unusual name" do

      let(:tracking_id) do
        MyCompany::Model::TrackingId.create
      end

      let(:history) do
        MyCompany::Model::TrackingIdValidationHistory.new(:old_state => "Test")
      end

      before do
        tracking_id.validation_history << history
      end

      it "allows creation of the embedded document" do
        tracking_id.validation_history.size.should == 1
      end

      it "saves the relation" do
        history.should be_persisted
      end

      it "remains on reload" do
        tracking_id.reload.validation_history.size.should == 1
      end
    end

    context "when the relation has address in the name" do

      let(:slave) do
        Slave.new(:first_name => "Test")
      end

      before do
        ActiveSupport::Inflector.inflections do |inflect|
          inflect.singular("address_numbers", "address_number")
        end
        slave.address_numbers << AddressNumber.new(:country_code => 1)
        slave.save
      end

      it "requires an inflection to determine the class" do
        slave.reload.address_numbers.size.should == 1
      end
    end

    context "when the parent and child have a cyclic relation" do

      context "when the parent is a new record" do

        let(:parent_role) do
          Role.new
        end

        let(:child_role) do
          Role.new
        end

        before do
          parent_role.child_roles = [ child_role ]
        end

        it "sets the target of the relation" do
          parent_role.child_roles.should == [ child_role ]
        end

        it "sets the base on the inverse relation" do
          child_role.parent_role.should == parent_role
        end

        it "sets the same instance on the inverse relation" do
          child_role.parent_role.should eql(parent_role)
        end

        it "does not save the target" do
          child_role.should_not be_persisted
        end

        it "sets the parent on the child" do
          child_role._parent.should == parent_role
        end

        it "sets the metadata on the child" do
          child_role.metadata.should_not be_nil
        end

        it "sets the index on the child" do
          child_role._index.should == 0
        end
      end

      context "when the parent is not a new record" do

        let(:parent_role) do
          Role.create(:name => "CTO")
        end

        let(:child_role) do
          Role.new
        end

        before do
          parent_role.child_roles = [ child_role ]
        end

        it "saves the target" do
          child_role.should be_persisted
        end
      end
    end
  end

  describe "#= nil" do

    context "when the relationship is polymorphic" do

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

        it "sets the relation to empty in the database" do
          person.reload.addresses.should be_empty
        end

        it "removed the inverse relation" do
          address.addressable.should be_nil
        end

        it "deletes the child document" do
          address.should be_destroyed
        end
      end

      context "when setting on a reload" do

        let(:person) do
          Person.create(:ssn => "437-11-1112")
        end

        let(:address) do
          Address.new
        end

        let(:reloaded) do
          person.reload
        end

        before do
          person.reload.addresses = [ address ]
          person.reload.addresses = nil
        end

        it "sets the relation to empty" do
          person.addresses.should be_empty
        end

        it "sets the relation to empty in the database" do
          reloaded.addresses.should be_empty
        end
      end
    end

    context "when the relationship is cyclic" do

      context "when the parent is a new record" do

        let(:parent_role) do
          Role.new
        end

        let(:child_role) do
          Role.new
        end

        before do
          parent_role.child_roles = [ child_role ]
          parent_role.child_roles = nil
        end

        it "sets the relation to empty" do
          parent_role.child_roles.should be_empty
        end

        it "removes the inverse relation" do
          child_role.parent_role.should be_nil
        end
      end

      context "when the inverse is already nil" do

        let(:parent_role) do
          Role.new
        end

        before do
          parent_role.child_roles = nil
        end

        it "sets the relation to empty" do
          parent_role.child_roles.should be_empty
        end
      end

      context "when the documents are not new records" do

        let(:parent_role) do
          Role.create
        end

        let(:child_role) do
          Role.new
        end

        before do
          parent_role.child_roles = [ child_role ]
          parent_role.child_roles = nil
        end

        it "sets the relation to empty" do
          parent_role.child_roles.should be_empty
        end

        it "removed the inverse relation" do
          child_role.parent_role.should be_nil
        end

        it "deletes the child document" do
          child_role.should be_destroyed
        end
      end
    end
  end

  describe "#avg" do

    let(:person) do
      Person.new(:ssn => "123-45-6789")
    end

    let(:address_one) do
      Address.new(:number => 5)
    end

    let(:address_two) do
      Address.new(:number => 10)
    end

    before do
      person.addresses.push(address_one, address_two)
    end

    let(:avg) do
      person.addresses.avg(:number)
    end

    it "returns the average value of the supplied field" do
      avg.should == 7.5
    end
  end

  [ :build, :new ].each do |method|

    describe "#build" do

      context "when the relation is not cyclic" do

        let(:person) do
          Person.new
        end

        let(:address) do
          person.addresses.send(method, :street => "Bond") do |address|
            address.state = "CA"
          end
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

        it "calls the passed block" do
          address.state.should == "CA"
        end
      end

      context "when the relation is cyclic" do

        let(:parent_role) do
          Role.new
        end

        let(:child_role) do
          parent_role.child_roles.send(method, :name => "CTO")
        end

        it "appends to the target" do
          parent_role.child_roles.should == [ child_role ]
        end

        it "sets the base on the inverse relation" do
          child_role.parent_role.should == parent_role
        end

        it "does not save the new document" do
          child_role.should_not be_persisted
        end

        it "sets the parent on the child" do
          child_role._parent.should == parent_role
        end

        it "sets the metadata on the child" do
          child_role.metadata.should_not be_nil
        end

        it "sets the index on the child" do
          child_role._index.should == 0
        end

        it "writes to the attributes" do
          child_role.name.should == "CTO"
        end
      end

      context "when providing nested attributes" do

        let(:person) do
          Person.create(:ssn => "555-11-2222")
        end

        let(:address) do
          person.addresses.send(
            method,
            :street => "Bond",
            :locations_attributes => { "1" => { "name" => "Home" } }
          )
        end

        context "when followed by a save" do

          before do
            address.save
          end

          let(:location) do
            person.reload.addresses.first.locations.first
          end

          it "persists the deeply embedded document" do
            location.name.should == "Home"
          end
        end
      end
    end
  end

  describe "#clear" do

    context "when the parent has been persisted" do

      let(:person) do
        Person.create(:ssn => "123-45-9999")
      end

      context "when the children are persisted" do

        let!(:address) do
          person.addresses.create(:street => "High St")
        end

        let!(:relation) do
          person.addresses.clear
        end

        it "clears out the relation" do
          person.addresses.should be_empty
        end

        it "marks the documents as deleted" do
          address.should be_destroyed
        end

        it "deletes the documents from the db" do
          person.reload.addresses.should be_empty
        end

        it "returns the relation" do
          relation.should == []
        end
      end

      context "when the children are not persisted" do

        let!(:address) do
          person.addresses.build(:street => "High St")
        end

        let!(:relation) do
          person.addresses.clear
        end

        it "clears out the relation" do
          person.addresses.should be_empty
        end
      end
    end

    context "when the parent is not persisted" do

      let(:person) do
        Person.new
      end

      let!(:address) do
        person.addresses.build(:street => "High St")
      end

      let!(:relation) do
        person.addresses.clear
      end

      it "clears out the relation" do
        person.addresses.should be_empty
      end
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

    context "when the relation is not cyclic" do

      let(:person) do
        Person.create(:ssn => "333-22-1234")
      end

      let!(:address) do
        person.addresses.create(:street => "Bond") do |address|
          address.state = "CA"
        end
      end

      it "appends to the target" do
        person.reload.addresses.should == [ address ]
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

      it "calls the passed block" do
        address.state.should == "CA"
      end

      context "when embedding a multi word named document" do

        let!(:component) do
          person.address_components.create(:street => "Test")
        end

        it "saves the embedded document" do
          person.reload.address_components.first.should == component
        end
      end
    end

    context "when the relation is cyclic" do

      let!(:entry) do
        Entry.create(:title => "hi")
      end

      let!(:child_entry) do
        entry.child_entries.create(:title => "hello")
      end

      it "creates a new child" do
        child_entry.should be_persisted
      end
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

          let!(:deleted) do
            person.addresses.send(
              method,
              :conditions => { :street => "Bond" }
            )
          end

          it "removes the matching documents" do
            person.addresses.size.should == 1
          end

          it "returns the number deleted" do
            deleted.should == 1
          end
        end

        context "when conditions are not provided" do

          let!(:deleted) do
            person.addresses.send(method)
          end

          it "removes all documents" do
            person.addresses.size.should == 0
          end

          it "returns the number deleted" do
            deleted.should == 2
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

          let!(:deleted) do
            person.addresses.send(
              method,
              :conditions => { :street => "Bond" }
            )
          end

          it "deletes the matching documents" do
            person.addresses.count.should == 1
          end

          it "deletes the matching documents from the db" do
            person.reload.addresses.count.should == 1
          end

          it "returns the number deleted" do
            deleted.should == 1
          end
        end

        context "when conditions are not provided" do

          let!(:deleted) do
            person.addresses.send(method)
          end

          it "deletes all the documents" do
            person.addresses.count.should == 0
          end

          it "deletes all the documents from the db" do
            person.reload.addresses.count.should == 0
          end

          it "returns the number deleted" do
            deleted.should == 2
          end
        end

        context "when removing and resaving" do

          let(:owner) do
            PetOwner.create(:title => "AKC")
          end

          before do
            owner.pet = Pet.new(:name => "Fido")
            owner.pet.vet_visits << VetVisit.new(:date => Date.today)
            owner.save!
            owner.pet.vet_visits.destroy_all
          end

          it "removes the documents" do
            owner.pet.vet_visits.should be_empty
          end

          it "allows addition and a resave" do
            owner.pet.vet_visits << VetVisit.new(:date => Date.today)
            owner.save!
            owner.pet.vet_visits.first.should be_persisted
          end
        end
      end
    end
  end

  describe "#exists?" do

    let!(:person) do
      Person.create(:ssn => "292-19-4239")
    end

    context "when documents exist in the database" do

      before do
        person.addresses.create(:street => "Bond St")
      end

      it "returns true" do
        person.addresses.exists?.should == true
      end
    end

    context "when no documents exist in the database" do

      before do
        person.addresses.build(:street => "Hyde Park Dr")
      end

      it "returns false" do
        person.addresses.exists?.should == false
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
        person.addresses.find_or_create_by(:street => "King") do |address|
          address.state = "CA"
        end
      end

      it "sets the new document attributes" do
        found.street.should == "King"
      end

      it "returns a newly persisted document" do
        found.should be_persisted
      end

      it "calls the passed block" do
        found.state.should == "CA"
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
        person.addresses.find_or_initialize_by(:street => "King") do |address|
          address.state = "CA"
        end
      end

      it "sets the new document attributes" do
        found.street.should == "King"
      end

      it "returns a non persisted document" do
        found.should_not be_persisted
      end

      it "calls the passed block" do
        found.state.should == "CA"
      end
    end
  end

  describe "#max" do

    let(:person) do
      Person.new(:ssn => "123-45-6789")
    end

    let(:address_one) do
      Address.new(:number => 5)
    end

    let(:address_two) do
      Address.new(:number => 10)
    end

    before do
      person.addresses.push(address_one, address_two)
    end

    let(:max) do
      person.addresses.max(:number)
    end

    it "returns the max value of the supplied field" do
      max.should == 10
    end
  end

  describe "#method_missing" do

    let!(:person) do
      Person.create(:ssn => "333-33-3333")
    end

    let!(:address_one) do
      person.addresses.create(:street => "Market", :state => "CA")
    end

    let!(:address_two) do
      person.addresses.create(:street => "Madison", :state => "NY")
    end

    context "when providing a single criteria" do

      context "when using a simple criteria" do

        let(:addresses) do
          person.addresses.where(:state => "CA")
        end

        it "applies the criteria to the documents" do
          addresses.should == [ address_one ]
        end
      end

      context "when using an $or criteria" do

        let(:addresses) do
          person.addresses.any_of({ :state => "CA" }, { :state => "NY" })
        end

        it "applies the criteria to the documents" do
          addresses.should == [ address_one, address_two ]
        end
      end
    end

    context "when providing a criteria class method" do

      let(:addresses) do
        person.addresses.california
      end

      it "applies the criteria to the documents" do
        addresses.should == [ address_one ]
      end
    end

    context "when chaining criteria" do

      let(:addresses) do
        person.addresses.california.where(:street.in => [ "Market" ])
      end

      it "applies the criteria to the documents" do
        addresses.should == [ address_one ]
      end
    end

    context "when delegating methods" do

      describe "#distinct" do

        it "returns the distinct values for the fields" do
          person.addresses.distinct(:street).should =~
            [ "Market",  "Madison"]
        end
      end
    end
  end

  describe "#min" do

    let(:person) do
      Person.new(:ssn => "123-45-6789")
    end

    let(:address_one) do
      Address.new(:number => 5)
    end

    let(:address_two) do
      Address.new(:number => 10)
    end

    before do
      person.addresses.push(address_one, address_two)
    end

    let(:min) do
      person.addresses.min(:number)
    end

    it "returns the min value of the supplied field" do
      min.should == 5
    end
  end

  [ :size, :length ].each do |method|

    describe "##{method}" do

      let(:person) do
        Person.create
      end

      before do
        person.addresses.create(:street => "Upper")
        person.addresses.build(:street => "Bond")
      end

      it "returns the number of persisted documents" do
        person.addresses.send(method).should == 2
      end
    end
  end

  describe "#sum" do

    let(:person) do
      Person.new(:ssn => "123-45-6789")
    end

    let(:address_one) do
      Address.new(:number => 5)
    end

    let(:address_two) do
      Address.new(:number => 10)
    end

    before do
      person.addresses.push(address_one, address_two)
    end

    let(:sum) do
      person.addresses.sum(:number)
    end

    it "returns the sum of all the supplied field values" do
      sum.should == 15
    end
  end

  context "when deeply embedding documents" do

    context "when building the tree through pushes" do

      let(:quiz) do
        Quiz.new
      end

      let(:page) do
        Page.new
      end

      let(:page_question) do
        PageQuestion.new
      end

      before do
        quiz.pages << page
        page.page_questions << page_question
      end

      let(:question) do
        quiz.pages.first.page_questions.first
      end

      it "sets up the hierarchy" do
        question.should == page_question
      end
    end

    context "when building the tree through builds" do

      let!(:quiz) do
        Quiz.new
      end

      let!(:page) do
        quiz.pages.build
      end

      let!(:page_question) do
        page.page_questions.build
      end

      let(:question) do
        quiz.pages.first.page_questions.first
      end

      it "sets up the hierarchy" do
        question.should == page_question
      end
    end

    context "when creating a persisted tree" do

      let(:quiz) do
        Quiz.create
      end

      let(:page) do
        Page.new
      end

      let(:page_question) do
        PageQuestion.new
      end

      let(:question) do
        quiz.pages.first.page_questions.first
      end

      before do
        quiz.pages << page
        page.page_questions << page_question
      end

      it "sets up the hierarchy" do
        question.should == page_question
      end

      context "when reloading" do

        let(:from_db) do
          quiz.reload
        end

        let(:reloaded_question) do
          from_db.pages.first.page_questions.first
        end

        it "reloads the entire tree" do
          reloaded_question.should == question
        end
      end
    end
  end
end
