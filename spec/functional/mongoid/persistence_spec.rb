require "spec_helper"

describe Mongoid::Persistence do

  before do
    [ Person, Post, Product, Game ].each(&:delete_all)
  end

  before(:all) do
    Mongoid.persist_in_safe_mode = true
    Mongoid.parameterize_keys = false
  end

  after(:all) do
    Mongoid.persist_in_safe_mode = false
    Mongoid.parameterize_keys = true
  end

  describe ".create" do

    context "when providing attributes" do

      let(:person) do
        Person.create(:title => "Sensei", :ssn => "666-66-6666")
      end

      it "it saves the document" do
        person.should be_persisted
      end

      it "returns the document" do
        person.should be_a_kind_of(Person)
      end

      context "on an embedded document" do

        subject { Address.create(:addressable => person) }

        it { should be_persisted }

        it { should be_a_kind_of(Address) }
      end
    end

    context "when passing in a block" do

      let(:person) do
        Person.create do |peep|
          peep.ssn = "666-66-6666"
        end
      end

      it "sets the attributes" do
        person.ssn.should eq("666-66-6666")
      end

      it "persists the document" do
        person.should be_persisted
      end
    end
  end

  describe ".create!" do

    context "inserting with a field that is not unique" do

      context "when a unique index exists" do

        before do
          Person.create_indexes
        end

        let!(:person) do
          Person.create!(:ssn => "555-55-9999")
        end

        it "raises an error" do
          expect {
            Person.create!(:ssn => "555-55-9999")
          }.to raise_error
        end
      end
    end

    context "when passing in a block" do

      let(:person) do
        Person.create! do |peep|
          peep.ssn = "666-66-6666"
        end
      end

      it "sets the attributes" do
        person.ssn.should eq("666-66-6666")
      end

      it "persists the document" do
        person.should be_persisted
      end
    end

    context "when setting the composite key" do

      let(:account) do
        Account.create!(:name => "Hello")
      end

      it "saves the document" do
        account.should be_persisted
      end
    end

    context "when a callback returns false" do

      it "raises a callback error" do
        expect { Oscar.create! }.to raise_error(Mongoid::Errors::Callback)
      end
    end
  end

  [ :delete, :destroy ].each do |method|

    describe "##{method}" do

      let(:person) do
        Person.create(:ssn => "218-32-6789")
      end

      context "when removing a root document" do

        let!(:deleted) do
          person.send(method)
        end

        it "deletes the document from the collection" do
          expect {
            Person.find(person.id)
          }.to raise_error
        end

        it "returns true" do
          deleted.should be_true
        end
      end

      context "when removing an embedded document" do

        let(:address) do
          person.addresses.build(:street => "Bond Street")
        end

        context "when the document is not yet saved" do

          before do
            address.send(method)
          end

          it "removes the document from the parent" do
            person.addresses.should be_empty
          end

          it "removes the attributes from the parent" do
            person.raw_attributes["addresses"].should be_nil
          end
        end

        context "when the document has been saved" do

          before do
            address.save
            address.send(method)
          end

          let(:from_db) do
            Person.find(person.id)
          end

          it "removes the object from the parent and database" do
            from_db.addresses.should be_empty
          end
        end
      end

      context "when removing deeply embedded documents" do

        context "when the document has been saved" do

          let(:address) do
            person.addresses.create(:street => "Bond Street")
          end

          let(:location) do
            address.locations.create(:name => "Home")
          end

          let(:from_db) do
            Person.find(person.id)
          end

          before do
            location.send(method)
          end

          it "removes the object from the parent and database" do
            from_db.addresses.first.locations.should be_empty
          end
        end
      end
    end
  end

  describe "#save" do

    let(:person) do
      Person.new(:ssn => "811-82-8345")
    end

    context "when saving with a hash field with invalid keys" do

      before do
        person.map = { "bad.key" => "value" }
      end

      it "raises an error" do
        expect { person.save }.to raise_error(BSON::InvalidKeyName)
      end
    end

    context "when validation passes" do

      it "returns true" do
        person.save.should be_true
      end
    end

    context "when validation fails" do

      let(:address) do
        person.addresses.create(:city => "London")
      end

      before do
        address.save
      end

      it "has the appropriate errors" do
        address.errors[:street].should eq(["can't be blank"])
      end
    end

    context "when modifying the entire hierarchy" do

      context "when performing modification and insert ops" do

        let(:person) do
          Person.create(:title => "Blah", :ssn => "244-01-1112")
        end

        let!(:address) do
          person.addresses.build(:street => "Bond St")
        end

        let!(:name) do
          person.create_name(:first_name => "Tony")
        end

        let(:from_db) do
          Person.find(person.id)
        end

        before do
          person.title = "King"
          name.first_name = "Ryan"
        end

        it "saves the root document" do
          person.save
          person.title.should eq("King")
        end

        it "saves embedded many relations" do
          person.save
          person.addresses.first.street.should eq("Bond St")
        end

        it "saves embedded one relations" do
          person.save
          person.name.first_name.should eq("Ryan")
        end

        it "persists with proper set and push modifiers" do
          person.atomic_updates.should eq({
            "$set" => {
              "title" => "King",
              "name.first_name" => "Ryan"
            },
            "$pushAll"=> {
              "addresses" => [ { "_id" => address.id, "street" => "Bond St" } ]
            }
          })
        end
      end

      context "when combining modifications and pushes" do

        let!(:person) do
          Person.create(
            :title => "Blah",
            :ssn => "244-01-1112",
            :addresses => [ address ]
          )
        end

        let!(:address) do
          Address.new(
            :number => 101,
            :street => 'South St',
            :locations => [ location ]
          )
        end

        let!(:location) do
          Location.new(:name => 'Work')
        end

        let(:from_db) do
          Person.find(person.id)
        end

        before do
          address.number = 102
          person.addresses << Address.new(:street => "North Ave")
          person.save
        end

        it "saves modifications to existing embedded docs" do
          from_db.addresses[0].number.should eq(102)
        end

        it "saves modifications to new embedded docs" do
          from_db.addresses[1].street.should eq('North Ave')
        end

        it "saves modifications to deeply embedded docs" do
          from_db.addresses[0].locations.first.name.should eq('Work')
        end
      end

      context "when removing elements without using delete or destroy" do

        let!(:person) do
          Person.create!(:title => "Blah", :ssn => "244-01-1112")
        end

        let(:from_db) do
          Person.find(person.id)
        end

        before do
          person.create_name(:first_name => "Tony")
          person.name = nil
          person.save
        end

        it "saves the hierarchy" do
          person.name.should be_nil
        end
      end
    end
  end

  describe "save!" do

    context "when saving with a hash field with invalid keys" do

      let(:person) do
        Person.new
      end

      before do
        person.map = { "bad.key" => "value" }
      end

      it "raises an error" do
        expect { person.save! }.to raise_error(BSON::InvalidKeyName)
      end
    end

    context "inserting with a field that is not unique" do

      context "when a unique index exists" do

        let(:person) do
          Person.new(:ssn => "555-55-9999")
        end

        before do
          Person.create!(:ssn => "555-55-9999")
        end

        it "raises an error" do
          expect { person.save! }.to raise_error
        end
      end
    end

    context "with a validation error" do

      let(:person) do
        Person.new
      end

      let!(:service) do
        Service.new(:person => person, :sid => "a")
      end

      it 'raises an error with multiple save attempts' do
        expect { subject.save! }.should raise_error
        expect { subject.save! }.should raise_error
      end
    end

    context "when a callback returns false" do

      let(:oscar) do
        Oscar.new
      end

      it "raises a callback error" do
        expect { oscar.save! }.to raise_error(Mongoid::Errors::Callback)
      end
    end
  end

  describe "#update_attribute" do

    let(:post) do
      Post.new
    end

    context "when setting an array field" do

      let(:person) do
        Person.create(:ssn => "432-11-1123", :aliases => [])
      end

      before do
        person.update_attribute(:aliases, person.aliases << "Bond")
      end

      it "sets the new value in the document" do
        person.aliases.should eq([ "Bond" ])
      end

      it "persists the changes" do
        person.reload.aliases.should eq([ "Bond" ])
      end
    end

    context "when setting a boolean field" do

      context "when the field is true" do

        let(:person) do
          Person.new(:ssn => "234-11-1232", :terms => true)
        end

        context "when setting to false" do

          before do
            person.update_attribute(:terms, false)
          end

          it "persists the document" do
            person.should be_persisted
          end

          it "changes the attribute value" do
            person.terms.should be_false
          end

          it "persists the changes" do
            person.reload.terms.should be_false
          end
        end
      end
    end

    context "when saving with a hash field with invalid keys" do

      let(:person) do
        Person.new
      end

      it "raises an error" do
        expect {
          person.update_attribute(:map, { "bad.key" => "value" })
        }.to raise_error(BSON::InvalidKeyName)
      end
    end

    context "when provided a symbol attribute name" do

      context "when the document is valid" do

        before do
          post.update_attribute(:title, "Testing")
        end

        it "sets the attribute" do
          post.title.should eq("Testing")
        end

        it "saves the document" do
          post.should be_persisted
        end
      end

      context "when updating to the same value" do

        before do
          post.update_attribute(:title, "Testing")
        end

        it "returns true" do
          post.update_attribute(:title, "Testing").should be_true
        end
      end

      context "when the document is invalid" do

        before do
          post.update_attribute(:title, "$invalid")
        end

        it "sets the attribute" do
          post.title.should eq("$invalid")
        end

        it "saves the document" do
          post.should be_persisted
        end
      end

      context "when the document has been destroyed" do

        before do
          post.delete
        end

        it "raises an error" do
          expect {
            post.update_attribute(:title, "something")
          }.to raise_error
        end
      end
    end

    context "when provided a string attribute name" do

      context "when the document is valid" do

        before do
          post.update_attribute("title", "Testing")
        end

        it "sets the attribute" do
          post.title.should eq("Testing")
        end

        it "saves the document" do
          post.should be_persisted
        end
      end

      context "when the document is invalid" do

        before do
          post.update_attribute("title", "$invalid")
        end

        it "sets the attribute" do
          post.title.should eq("$invalid")
        end

        it "saves the document" do
          post.should be_persisted
        end
      end
    end

    context "when persisting a localized field" do

      let!(:product) do
        Product.create(:description => "The bomb")
      end

      before do
        ::I18n.locale = :de
        product.update_attribute(:description, "Die Bombe")
      end

      after do
        ::I18n.locale = :en
      end

      let(:attributes) do
        product.attributes["description"]
      end

      it "persists the en locale" do
        attributes["en"].should eq("The bomb")
      end

      it "persists the de locale" do
        attributes["de"].should eq("Die Bombe")
      end
    end
  end

  describe "#update_attributes" do

    context "when saving with a hash field with invalid keys" do

      let(:person) do
        Person.create(:ssn => "717-98-2342")
      end

      it "raises an error" do
        expect {
          person.update_attributes(:map => { "bad.key" => "value" })
        }.to raise_error(Mongo::OperationFailure)
      end
    end

    context "when validation passes" do

      let(:person) do
        Person.create(:ssn => "717-98-9999")
      end

      let!(:saved) do
        person.update_attributes(:pets => false)
      end

      let(:from_db) do
        Person.find(person.id)
      end

      it "returns true" do
        saved.should be_true
      end

      it "saves the attributes" do
        from_db.pets.should be_false
      end
    end

    context "when the document has been destroyed" do

      let!(:person) do
        Person.create(:ssn => "717-98-9999")
      end

      before do
        person.delete
      end

      it "raises an error" do
        expect {
          person.update_attributes(:title => "something")
        }.to raise_error
      end
    end

    context "when updating through a one-to-one relation" do

      let(:person) do
        Person.create!(:ssn => "666-77-8888")
      end

      let(:game) do
        Game.create(:person => person)
      end

      before do
        person.update_attributes!(:ssn => "444-44-4444")
        game.person.update_attributes!(:ssn => "555-66-7777")
      end

      let(:from_db) do
        Person.find(person.id)
      end

      it "saves the attributes" do
        person.ssn.should eq("555-66-7777")
      end
    end

    context "on a new record" do

      let(:person) do
        Person.new
      end

      before do
        person.update_attributes(:ssn => "555-55-1235", :pets => false, :title => nil)
      end

      it "saves the new record" do
        Person.find(person.id).should_not be_nil
      end
    end

    context "when passing in a relation" do

      context "when providing a parent to a referenced in" do

        let!(:person) do
          Person.create(:ssn => "666-66-6666")
        end

        let!(:post) do
          Post.create(:title => "Testing")
        end

        context "when the relation has not yet been touched" do

          before do
            post.update_attributes(:person => person)
          end

          it "sets the instance of the relation" do
            person.posts.should eq([ post ])
          end

          it "sets properly through method_missing" do
            person.posts.to_a.should eq([ post ])
          end

          it "persists the reference" do
            person.posts(true).should eq([ post ])
          end
        end

        context "when the relation has been touched" do

          before do
            person.posts
            post.update_attributes(:person => person)
          end

          it "sets the instance of the relation" do
            person.posts.should eq([ post ])
          end

          it "sets properly through method_missing" do
            person.posts.to_a.should eq([ post ])
          end

          it "persists the reference" do
            person.posts(true).should eq([ post ])
          end
        end
      end
    end

    context "when in a deeply nested hierarchy" do

      let!(:person) do
        Person.new(:title => "The Boss", :ssn => "098-76-5432")
      end

      let!(:phone_number) do
        Phone.new(:number => "123-456-7890")
      end

      let!(:country_code) do
        CountryCode.new(:code => 1)
      end

      before do
        phone_number.country_code = country_code
        person.phone_numbers << phone_number
        person.save
      end

      it "sets the first level document" do
        person.phone_numbers.first.should eq(phone_number)
      end

      it "sets the second level document" do
        person.phone_numbers.first.country_code.should eq(country_code)
      end

      context "when updating the first level document" do

        let(:phone) do
          person.phone_numbers.first
        end

        before do
          phone.number = "098-765-4321"
          phone.update_attributes(:number => "098-765-4321")
        end

        it "sets the new attributes" do
          phone.number.should eq("098-765-4321")
        end

        context "when reloading the root" do

          let(:reloaded) do
            person.reload
          end

          it "saves the new attributes" do
            reloaded.phone_numbers.first.number.should eq("098-765-4321")
          end
        end
      end
    end
  end

  describe "#update_attributes!" do

    context "when a callback returns false" do

      let(:oscar) do
        Oscar.new
      end

      it "raises a callback error" do
        expect {
          oscar.update_attributes!(:title => "The Grouch")
        }.to raise_error(Mongoid::Errors::Callback)
      end
    end
  end

  [ :delete_all, :destroy_all ].each do |method|

    describe "##{method}" do

      let!(:person) do
        Person.create(:ssn => "712-34-5111")
      end

      let!(:removed) do
        Person.send(method)
      end

      it "removes all the documents" do
        Person.count.should eq(0)
      end

      it "returns the number of documents removed" do
        removed.should eq(1)
      end
    end
  end
end
