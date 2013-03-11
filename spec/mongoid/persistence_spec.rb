require "spec_helper"

describe Mongoid::Persistence do

  describe ".create" do

    context "when provided an array of attributes" do

      context "when no block is passed" do

        let(:people) do
          Person.create([{ title: "sir" }, { title: "madam" }])
        end

        it "creates the first document" do
          people.first.title.should eq("sir")
        end

        it "persists the first document" do
          people.first.should be_persisted
        end

        it "creates the second document" do
          people.last.title.should eq("madam")
        end

        it "persists the second document" do
          people.last.should be_persisted
        end
      end

      context "when no block is passed" do

        let(:people) do
          Person.create([{ title: "sir" }, { title: "madam" }]) do |person|
            person.age = 36
          end
        end

        it "creates the first document" do
          people.first.title.should eq("sir")
        end

        it "persists the first document" do
          people.first.should be_persisted
        end

        it "passes the block to the first document" do
          people.first.age.should eq(36)
        end

        it "creates the second document" do
          people.last.title.should eq("madam")
        end

        it "persists the second document" do
          people.last.should be_persisted
        end

        it "passes the block to the second document" do
          people.last.age.should eq(36)
        end
      end
    end

    context "when providing attributes" do

      let(:person) do
        Person.create(title: "Sensei")
      end

      it "it saves the document" do
        person.should be_persisted
      end

      it "returns the document" do
        person.should be_a_kind_of(Person)
      end

      context "when creating an embedded document" do

        let(:address) do
          Address.create(addressable: person)
        end

        it "persists the document" do
          address.should be_persisted
        end
      end

      context "when creating an embedded document with store_as option" do

        let(:user) do
          User.create
        end

        before(:all) do
          User.embeds_many(
            :addresses,
            class_name: "Address",
            store_as: "user_adresses",
            validate: false
          )
          Address.embedded_in :user
        end

        before do
          user.addresses.create!(city: "nantes")
        end

        let(:document) do
          user.collection.find(_id: user.id).first
        end

        it "should not persist in address key on User document" do
          document.keys.should_not include("addresses")
        end

        it "should persist on user_addesses key on User document" do
          document.keys.should include("user_adresses")
        end
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

    context "when provided an array of attributes" do

      context "when no block is passed" do

        let(:people) do
          Person.create!([{ title: "sir" }, { title: "madam" }])
        end

        it "creates the first document" do
          people.first.title.should eq("sir")
        end

        it "persists the first document" do
          people.first.should be_persisted
        end

        it "creates the second document" do
          people.last.title.should eq("madam")
        end

        it "persists the second document" do
          people.last.should be_persisted
        end
      end

      context "when no block is passed" do

        let(:people) do
          Person.create!([{ title: "sir" }, { title: "madam" }]) do |person|
            person.age = 36
          end
        end

        it "creates the first document" do
          people.first.title.should eq("sir")
        end

        it "persists the first document" do
          people.first.should be_persisted
        end

        it "passes the block to the first document" do
          people.first.age.should eq(36)
        end

        it "creates the second document" do
          people.last.title.should eq("madam")
        end

        it "persists the second document" do
          people.last.should be_persisted
        end

        it "passes the block to the second document" do
          people.last.age.should eq(36)
        end
      end
    end

    context "inserting with a field that is not unique" do

      context "when a unique index exists" do

        before do
          Person.create_indexes
        end

        it "raises an error" do
          expect {
            4.times { Person.with(safe: true).create!(ssn: "555-55-1029") }
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
        Account.create!(name: "Hello")
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
        Person.create
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

        it "resets the flagged for destroy flag" do
          person.should_not be_flagged_for_destroy
        end
      end

      context "when removing an embedded document" do

        let(:address) do
          person.addresses.build(street: "Bond Street")
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

          it "resets the flagged for destroy flag" do
            address.should_not be_flagged_for_destroy
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
            person.addresses.create(street: "Bond Street")
          end

          let(:location) do
            address.locations.create(name: "Home")
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

          it "resets the flagged for destroy flag" do
            location.should_not be_flagged_for_destroy
          end
        end
      end
    end
  end

  describe "#save" do

    let(:person) do
      Person.create
    end

    context "when skipping validation" do

      context "when no relations are involved" do

        let(:account) do
          Account.new
        end

        let!(:saved) do
          account.save(validate: false)
        end

        it "returns true" do
          saved.should be_true
        end

        it "saves the document" do
          account.should be_persisted
        end

        it "does not add any validation errors" do
          account.errors.should be_empty
        end
      end

      context "when saving document that is a belongs to child" do

        let(:account) do
          Account.create
        end

        let(:alert) do
          Alert.new(account: account)
        end

        context "when validating presence of the parent" do

          before do
            Alert.validates(:message, :account, presence: true)
          end

          after do
            Alert.reset_callbacks(:validate)
          end

          context "when the parent validates associated on the child" do

            before do
              alert.save(validate: false)
            end

            it "clears any errors off the document" do
              alert.errors.should be_empty
            end

            context "when the document is not new" do

              before do
                alert.save(validate: false)
              end

              it "clears any errors off the document" do
                alert.errors.should be_empty
              end
            end
          end
        end
      end
    end

    context "when the document has been instantiated with limited fields" do

      before do
        person.age = 20
        person.save
      end

      context "when a default is excluded" do

        let(:limited) do
          Person.only(:_id).find(person.id)
        end

        it "does not flag the excluded fields as dirty" do
          limited.changes.should be_empty
        end

        it "does not overwrite with the default" do
          limited.save
          limited.reload.age.should eq(20)
        end
      end

      context "when iterating over the documents" do

        let(:limited) do
          Person.only(:_id)
        end

        it "does not flag any changes" do
          limited.each do |person|
            person.changes.should be_empty
          end
        end
      end
    end

    context "when validation passes" do

      it "returns true" do
        person.save.should be_true
      end
    end

    context "when validation fails" do

      let(:address) do
        person.addresses.create(city: "London")
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
          Person.create(title: "Blah")
        end

        let!(:address) do
          person.addresses.build(street: "Bond St")
        end

        let!(:name) do
          person.create_name(first_name: "Tony")
        end

        let(:from_db) do
          Person.find(person.id)
        end

        before do
          person.title = "King"
          name.first_name = "Ryan"
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

        context "when saving the document" do

          it "saves the root document" do
            person.title.should eq("King")
          end

          it "saves embedded many relations" do
            person.addresses.first.street.should eq("Bond St")
          end

          it "saves embedded one relations" do
            person.name.first_name.should eq("Ryan")
          end
        end
      end

      context "when combining modifications and pushes" do

        let!(:location) do
          Location.new(name: 'Work')
        end

        let!(:address) do
          Address.new(
            number: 101,
            street: 'South St',
            locations: [ location ]
          )
        end

        let!(:person) do
          Person.create(
            title: "Blah",
            addresses: [ address ]
          )
        end

        let(:from_db) do
          Person.find(person.id)
        end

        before do
          address.number = 102
          person.addresses << Address.new(street: "North Ave")
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
          Person.create!(title: "Blah")
        end

        let(:from_db) do
          Person.find(person.id)
        end

        before do
          person.create_name(first_name: "Tony")
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

    context "inserting with a field that is not unique" do

      context "when a unique index exists" do

        let(:person) do
          Person.new(ssn: "555-55-9999")
        end

        before do
          Person.create_indexes
          Person.create!(ssn: "555-55-9999")
        end

        it "raises an error" do
          expect { person.with(safe: true).save! }.to raise_error
        end
      end
    end

    context "with a validation error" do

      let(:person) do
        Person.new
      end

      let!(:service) do
        Service.new(person: person, sid: "a")
      end

      it "raises an error with multiple save attempts" do
        expect { subject.save! }.to raise_error
        expect { subject.save! }.to raise_error
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

    context "when a callback destroys the document" do

      let(:oscar) do
        Oscar.new(:destroy_after_save => true)
      end

      before do
        oscar.save!
      end

      it "flags the document as destroyed" do
        oscar.should be_destroyed
      end
    end
  end

  describe "#touch" do

    context "when the document is embedded" do

      let(:band) do
        Band.create(name: "Placebo")
      end

      let(:label) do
        band.create_label(name: "Mute", updated_at: 10.days.ago)
      end

      before do
        label.touch
      end

      it "updates the updated_at timestamp" do
        label.updated_at.should be_within(1).of(Time.now)
      end

      it "persists the changes" do
        label.reload.updated_at.should be_within(1).of(Time.now)
      end
    end

    context "when no relations have touch options" do

      context "when no updated at is defined" do

        let(:person) do
          Person.create
        end

        context "when no attribute is provided" do

          let!(:touched) do
            person.touch
          end

          it "returns true" do
            touched.should be_true
          end

          it "does not set the updated at field" do
            person[:updated_at].should be_nil
          end
        end

        context "when an attribute is provided" do

          let!(:touched) do
            person.touch(:lunch_time)
          end

          it "sets the attribute to the current time" do
            person.lunch_time.should be_within(5).of(Time.now)
          end

          it "persists the change" do
            person.reload.lunch_time.should be_within(5).of(Time.now)
          end

          it "returns true" do
            touched.should be_true
          end
        end

        context "when an attribute alias is provided" do

          let!(:touched) do
            person.touch(:aliased_timestamp)
          end

          it "sets the attribute to the current time" do
            person.aliased_timestamp.should be_within(5).of(Time.now)
          end

          it "persists the change" do
            person.reload.aliased_timestamp.should be_within(5).of(Time.now)
          end

          it "returns true" do
            touched.should be_true
          end
        end
      end

      context "when an updated at is defined" do

        let!(:agent) do
          Agent.create(updated_at: 2.days.ago)
        end

        context "when no attribute is provided" do

          let!(:touched) do
            agent.touch
          end

          it "sets the updated at to the current time" do
            agent.updated_at.should be_within(5).of(Time.now)
          end

          it "persists the change" do
            agent.reload.updated_at.should be_within(5).of(Time.now)
          end

          it "returns true" do
            touched.should be_true
          end

          it "keeps changes for next callback" do
            agent.changes.should_not be_empty
          end
        end

        context "when an attribute is provided" do

          let!(:touched) do
            agent.touch(:dob)
          end

          it "sets the updated at to the current time" do
            agent.updated_at.should be_within(5).of(Time.now)
          end

          it "sets the attribute to the current time" do
            agent.dob.should be_within(5).of(Time.now)
          end

          it "sets both attributes to the exact same time" do
            agent.updated_at.should eq(agent.dob)
          end

          it "persists the updated at change" do
            agent.reload.updated_at.should be_within(5).of(Time.now)
          end

          it "persists the attribute change" do
            agent.reload.dob.should be_within(5).of(Time.now)
          end

          it "returns true" do
            touched.should be_true
          end

          it "keeps changes for next callback" do
            agent.changes.should_not be_empty
          end
        end
      end

      context "when record is new" do

        let(:agent) do
          Agent.new(updated_at: 2.days.ago)
        end

        context "when no attribute is provided" do

          let!(:touched) do
            agent.touch
          end

          it "returns false" do
            touched.should be_false
          end
        end

        context "when an attribute is provided" do

          let!(:touched) do
            agent.touch(:dob)
          end

          it "returns false" do
            touched.should be_false
          end
        end
      end

      context "when creating the child" do

        let(:time) do
          Time.utc(2012, 4, 3, 12)
        end

        let(:jar) do
          Jar.new(_id: 1, updated_at: time).tap do |jar|
            jar.save!
          end
        end

        let!(:cookie) do
          jar.cookies.create!(updated_at: time)
        end

        it "does not touch the parent" do
          jar.updated_at.should eq(time)
        end
      end
    end

    context "when relations have touch options" do

      context "when the relation is nil" do

        let!(:agent) do
          Agent.create
        end

        context "when the relation autobuilds" do

          let!(:touched) do
            agent.touch
          end

          it "does nothing to the relation" do
            agent.instance_variable_get(:@agency).should be_nil
          end
        end
      end

      context "when the relation is not nil" do

        let!(:agent) do
          Agent.create
        end

        let!(:agency) do
          agent.create_agency.tap do |a|
            a.unset(:updated_at)
          end
        end

        let!(:touched) do
          agent.touch
        end

        it "sets the parent updated at to the current time" do
          agency.updated_at.should be_within(5).of(Time.now)
        end

        it "persists the change" do
          agency.reload.updated_at.should be_within(5).of(Time.now)
        end
      end

      context "when creating the child" do

        let!(:agency) do
          Agency.create
        end

        let!(:updated) do
          agency.updated_at
        end

        let!(:agent) do
          agency.agents.create
        end

        it "updates the parent's updated at" do
          agency.updated_at.should_not eq(updated)
        end
      end

      context "when destroying the child" do

        let!(:agency) do
          Agency.create
        end

        let!(:agent) do
          agency.agents.create
        end

        let!(:updated) do
          agency.updated_at
        end

        before do
          agent.destroy
        end

        it "updates the parent's updated at" do
          agency.updated_at.should_not eq(updated)
        end
      end
    end
  end

  describe "#update_attribute" do

    context "when the field is aliased" do

      let(:person) do
        Person.create
      end

      context "when setting via the field name" do

        before do
          person.update_attribute(:t, "testing")
        end

        it "updates the field" do
          person.t.should eq("testing")
        end

        it "persists the changes" do
          person.reload.t.should eq("testing")
        end
      end

      context "when setting via the field alias" do

        before do
          person.update_attribute(:test, "testing")
        end

        it "updates the field" do
          person.t.should eq("testing")
        end

        it "persists the changes" do
          person.reload.t.should eq("testing")
        end
      end
    end

    context "when setting an array field" do

      let(:person) do
        Person.create(aliases: [])
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
          Person.new(terms: true)
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

    context "when provided a symbol attribute name" do

      let(:post) do
        Post.new
      end

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

      let(:post) do
        Post.new
      end

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
        Product.create(description: "The bomb")
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

    context "when updating a deeply embedded document" do

      let!(:person) do
        Person.create
      end

      let!(:address) do
        person.addresses.create(street: "Winterfeldtstr")
      end

      let!(:location) do
        address.locations.create(name: "work")
      end

      let(:from_db) do
        Person.last.addresses.last.locations.last
      end

      before do
        from_db.update_attribute(:name, "home")
      end

      it "updates the attribute" do
        from_db.name.should eq("home")
      end

      it "persists the changes" do
        from_db.reload.name.should eq("home")
      end
    end
  end

  describe "#update_attributes" do

    context "when saving with a hash field with invalid keys" do

      let(:person) do
        Person.create
      end

      it "raises an error" do
        expect {
          person.with(safe: true).update_attributes(map: { "bad.key" => "value" })
        }.to raise_error(Moped::Errors::OperationFailure)
      end
    end

    context "when validation passes" do

      let(:person) do
        Person.create
      end

      let!(:saved) do
        person.update_attributes(pets: false)
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
        Person.create
      end

      before do
        person.delete
      end

      it "raises an error" do
        expect {
          person.update_attributes(title: "something")
        }.to raise_error
      end
    end

    context "when updating through a one-to-one relation" do

      let(:person) do
        Person.create!
      end

      let(:game) do
        Game.create(person: person)
      end

      before do
        person.update_attributes!(ssn: "444-44-4444")
        game.person.update_attributes!(ssn: "555-66-7777")
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
        person.update_attributes(pets: false, title: nil)
      end

      it "saves the new record" do
        Person.find(person.id).should_not be_nil
      end
    end

    context "when passing in a relation" do

      context "when providing an embedded child" do

        let!(:person) do
          Person.create
        end

        let!(:name) do
          person.create_name(first_name: "test", last_name: "user")
        end

        let(:new_name) do
          Name.new(first_name: "Rupert", last_name: "Parkes")
        end

        before do
          person.update_attributes(name: new_name)
        end

        it "updates the embedded document" do
          person.name.should eq(new_name)
        end

        it "persists the changes" do
          person.reload.name.should eq(new_name)
        end
      end

      context "when providing a parent to a referenced in" do

        let!(:person) do
          Person.create
        end

        let!(:post) do
          Post.create(title: "Testing")
        end

        context "when the relation has not yet been touched" do

          before do
            post.update_attributes(person: person)
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
            post.update_attributes(person: person)
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
        Person.new(title: "The Boss")
      end

      let!(:phone_number) do
        Phone.new(number: "123-456-7890")
      end

      let!(:country_code) do
        CountryCode.new(code: 1)
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
          phone.update_attributes(number: "098-765-4321")
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
          oscar.update_attributes!(title: "The Grouch")
        }.to raise_error(Mongoid::Errors::Callback)
      end
    end
  end

  describe "#upsert" do

    context "when the document validates on upsert" do

      let(:account) do
        Account.new(name: "testing")
      end

      context "when the document is not valid in the upsert context" do

        before do
          account.upsert
        end

        it "adds the validation errors" do
          account.errors[:nickname].should_not be_empty
        end

        it "does not upsert the document" do
          account.should be_a_new_record
        end
      end
    end

    context "when the document is new" do

      let!(:existing) do
        Band.create(name: "Photek")
      end

      context "when a matching document exists in the db" do

        let(:updated) do
          Band.new(name: "Tool") do |band|
            band.id = existing.id
          end
        end

        before do
          updated.with(safe: true).upsert
        end

        it "updates the existing document" do
          existing.reload.name.should eq("Tool")
        end
      end

      context "when no matching document exists in the db" do

        let(:insert) do
          Band.new(name: "Tool")
        end

        before do
          insert.with(safe: true).upsert
        end

        it "inserts a new document" do
          insert.reload.should eq(insert)
        end

        it "does not modify any fields" do
          insert.reload.name.should eq("Tool")
        end
      end
    end

    context "when the document is not new" do

      let!(:existing) do
        Band.create(name: "Photek")
      end

      context "when updating fields outside of the id" do

        before do
          existing.name = "Depeche Mode"
        end

        let!(:upsert) do
          existing.upsert
        end

        it "updates the existing document" do
          existing.reload.name.should eq("Depeche Mode")
        end

        it "returns true" do
          upsert.should be_true
        end
      end
    end
  end

  [ :delete_all, :destroy_all ].each do |method|

    describe "##{method}" do

      let!(:person) do
        Person.create(title: "sir")
      end

      context "when no conditions are provided" do

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

      context "when conditions are provided" do

        let!(:person_two) do
          Person.create
        end

        context "when in a conditions attribute" do

          let!(:removed) do
            Person.send(method, conditions: { title: "sir" })
          end

          it "removes the matching documents" do
            Person.count.should eq(1)
          end

          it "returns the number of documents removed" do
            removed.should eq(1)
          end
        end

        context "when no conditions attribute provided" do

          let!(:removed) do
            Person.send(method, title: "sir")
          end

          it "removes the matching documents" do
            Person.count.should eq(1)
          end

          it "returns the number of documents removed" do
            removed.should eq(1)
          end
        end
      end
    end
  end

  context "when a DateTime attribute is updated and persisted" do

    let(:user) do
      User.create!(last_login: 2.days.ago).tap do |u|
        u.last_login = DateTime.now
      end
    end

    it "reads for persistance as a UTC Time" do
      user.changes["last_login"].last.class.should eq(Time)
    end

    it "persists with no exceptions thrown" do
      user.save!
    end
  end

  context "when a Date attribute is persisted" do

    let(:user) do
      User.create!(account_expires: 2.years.from_now).tap do |u|
        u.account_expires = "2/2/2002".to_date
      end
    end

    it "reads for persistance as a UTC Time" do
      user.changes["account_expires"].last.class.should eq(Time)
    end

    it "persists with no exceptions thrown" do
      user.save!
    end
  end

  context "when setting floating point numbers" do

    context "when value is an empty string" do

      let(:person) do
        Person.new
      end

      before do
        Person.validates_numericality_of :blood_alcohol_content, allow_blank: true
      end

      it "does not set the value" do
        person.save.should be_true
      end
    end
  end

  context "when setting association foreign keys" do

    let(:game) do
      Game.new
    end

    let(:person) do
      Person.create
    end

    context "when value is an empty string" do

      before do
        game.person_id = ""
        game.save
      end

      it "sets the foreign key to empty" do
        game.reload.person_id.should be_blank
      end
    end

    context "when value is a populated string" do

      before do
        game.person_id = person.id.to_s
        game.save
      end

      it "sets the foreign key as ObjectID" do
        game.reload.person_id.should eq(person.id)
      end
    end

    context "when value is a ObjectID" do

      before do
        game.person_id = person.id
        game.save
      end

      it "keeps the the foreign key as ObjectID" do
        game.reload.person_id.should eq(person.id)
      end
    end
  end

  context "when the document is a subclass of a root class" do

    let!(:browser) do
      Browser.create(version: 3, name: "Test")
    end

    let(:collection) do
      Canvas.collection
    end

    let(:attributes) do
      collection.find({ name: "Test"}).first
    end

    it "persists the versions" do
      attributes["version"].should eq(3)
    end

    it "persists the type" do
      attributes["_type"].should eq("Browser")
    end

    it "persists the attributes" do
      attributes["name"].should eq("Test")
    end
  end

  context "when the document is a subclass of a subclass" do

    let!(:firefox) do
      Firefox.create(version: 2, name: "Testy")
    end

    let(:collection) do
      Canvas.collection
    end

    let(:attributes) do
      collection.find({ name: "Testy"}).first
    end

    before do
      Browser.create(name: 'Safari', version: '4.0.0')
    end

    it "persists the versions" do
      attributes["version"].should eq(2)
    end

    it "persists the type" do
      attributes["_type"].should eq("Firefox")
    end

    it "persists the attributes" do
      attributes["name"].should eq("Testy")
    end

    it "returns the document when querying for superclass" do
      Browser.where(name: "Testy").first.should eq(firefox)
    end

    it "returns the document when querying for root class" do
      Canvas.where(name: "Testy").first.should eq(firefox)
    end

    it 'returnss on of this subclasses if you find by _type' do
      Canvas.where(:_type.in => ['Firefox']).count.should eq(1)
    end
  end

  context "when the document has associations" do

    let!(:firefox) do
      Firefox.create(name: "firefox")
    end

    let!(:writer) do
      HtmlWriter.new(speed: 100)
    end

    let!(:circle) do
      Circle.new(radius: 50)
    end

    let!(:square) do
      Square.new(width: 300, height: 150)
    end

    let(:from_db) do
      Firefox.find(firefox.id)
    end

    before do
      firefox.writer = writer
      firefox.shapes << [ circle, square ]
      firefox.save!
    end

    it "properly persists the one-to-one type" do
      from_db.should be_a_kind_of(Firefox)
    end

    it "properly persists the one-to-one relations" do
      from_db.writer.should eq(writer)
    end

    it "properly persists the one-to-many type" do
      from_db.shapes.first.should eq(circle)
    end

    it "properly persists the one-to-many relations" do
      from_db.shapes.last.should eq(square)
    end

    it "properly sets up the parent relation" do
      from_db.shapes.first.should eq(circle)
    end

    it "properly sets up the entire hierarchy" do
      from_db.shapes.first.canvas.should eq(firefox)
    end
  end

  context "when the document is subclassed" do

    let!(:firefox) do
      Firefox.create(name: "firefox")
    end

    it "finds the document with String args" do
      Firefox.find(firefox.id.to_s).should eq(firefox)
    end

    context "when querying for parent documents" do

      let(:canvas) do
        Canvas.where(name: "firefox").first
      end

      it "returns matching subclasses" do
        canvas.should eq(firefox)
      end
    end
  end

  context "when deleting subclasses" do

    let!(:firefox) do
      Firefox.create(name: "firefox")
    end

    let!(:firefox2) do
      Firefox.create(name: "firefox 2")
    end

    let!(:browser) do
      Browser.create(name: "browser")
    end

    let!(:canvas) do
      Canvas.create(name: "canvas")
    end

    context "when deleting a single document" do

      before do
        firefox.delete
      end

      it "deletes from the parent class collection" do
        Canvas.count.should eq(3)
      end

      it "returns correct counts for child classes" do
        Firefox.count.should eq(1)
      end

      it "returns correct counts for root subclasses" do
        Browser.count.should eq(2)
      end
    end

    context "when deleting all documents" do

      before do
        Firefox.delete_all
      end

      it "deletes from the parent class collection" do
        Canvas.count.should eq(2)
      end

      it "returns correct counts for child classes" do
        Firefox.count.should eq(0)
      end

      it "returns correct counts for root subclasses" do
        Browser.count.should eq(1)
      end
    end
  end

  context "when document is a subclass and its parent is an embedded document" do

    let!(:canvas) do
      Canvas.create(name: "canvas")
    end

    before do
      canvas.create_palette
      canvas.palette.tools << Pencil.new
      canvas.palette.tools << Eraser.new
    end

    let(:from_db) do
      Canvas.find(canvas.id)
    end

    it "properly saves the subclasses" do
      from_db.palette.tools.map(&:class).should eq([Pencil, Eraser])
    end
  end

  context "Creating references_many documents from a parent association" do

    let!(:container) do
      ShippingContainer.create
    end

    let(:driver) do
      Driver.create
    end

    it "does not bleed relations from one subclass to another" do
      Truck.relations.keys.should =~ %w/ shipping_container driver bed /
      Car.relations.keys.should =~ %w/ shipping_container driver /
    end

    context "when appending new documents" do

      before do
        container.vehicles << Car.new
        container.vehicles << Truck.new
      end

      it "allows STI from << using model.new" do
        container.vehicles.map(&:class).should eq([ Car, Truck ])
      end
    end

    context "when appending persisted documents" do

      before do
        container.vehicles << Car.create
        container.vehicles << Truck.create
      end

      it "allows STI from << using model.create" do
        container.vehicles.map(&:class).should eq([ Car, Truck ])
      end
    end

    context "when building related documents" do

      before do
        container.vehicles.build({}, Car).save
        container.vehicles.build({}, Truck).save
      end

      it "allows STI from the build call" do
        container.vehicles.map(&:class).should eq([ Car, Truck ])
      end
    end

    context "when building with a type attribute" do

      before do
        container.vehicles.build({ "_type" => "Car" })
        container.vehicles.build({ "_type" => "Truck" })
      end

      it "respects the _type attribute from the build call" do
        container.vehicles.map(&:class).should eq([ Car, Truck ])
      end
    end

    context "when creating related documents" do

      before do
        container.vehicles.create({}, Car)
        container.vehicles.create({}, Truck)
      end

      it "allows STI from the create call" do
        container.vehicles.map(&:class).should eq([ Car, Truck ])
      end
    end

    context "when creating with a type attribute" do

      before do
        container.vehicles.create({ "_type" => "Car" })
        container.vehicles.create({ "_type" => "Truck" })
      end

      it "respects the _type attribute from the create call" do
        container.vehicles.map(&:class).should eq([ Car, Truck ])
      end
    end

    context "#find_or_initialize_by" do

      before do
        container.vehicles.find_or_initialize_by({ driver_id: driver.id }, Car)
      end

      it "initializes the given type document" do
        container.vehicles.map(&:class).should eq([ Car ])
      end

      it "initializes with the given attributes" do
        container.vehicles.map(&:driver).should eq([ driver ])
      end
    end

    context "#find_or_create_by" do

      before do
        container.vehicles.find_or_create_by({ driver_id: driver.id }, Car)
      end

      it "creates the given type document" do
        container.vehicles.map(&:class).should eq([ Car ])
      end

      it "creates with the given attributes" do
        container.vehicles.map(&:driver).should eq([ driver ])
      end

      it "creates the correct number of documents" do
        container.vehicles.size.should eq(1)
      end

      context "when executing with a found document" do

        before do
          container.vehicles.find_or_create_by({ driver_id: driver.id }, Car)
        end

        it "does not create an additional document" do
          container.vehicles.size.should eq(1)
        end
      end

      context "when executing with an additional new document" do

        before do
          container.vehicles.find_or_create_by({ driver_id: driver.id }, Truck)
        end

        it "creates the new additional document" do
          container.vehicles.size.should eq(2)
        end
      end
    end
  end
end
