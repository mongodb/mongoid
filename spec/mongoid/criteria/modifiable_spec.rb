require "spec_helper"

describe Mongoid::Criteria::Modifiable do

  describe "#create" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    context "when provided valid attributes" do
      let(:band) do
        criteria.create(genres: [ "electro" ])
      end

      it "returns the created document" do
        expect(band).to be_persisted
      end

      it "sets the criteria attributes" do
        expect(band.name).to eq("Depeche Mode")
      end

      it "sets the attributes passed to build" do
        expect(band.genres).to eq([ "electro" ])
      end
    end

    context "when provided a block" do

      context "when provided valid attributes & using block" do

        let(:band) do
          criteria.create do |c|
            c.genres = [ "electro" ]
          end
        end

        it "returns the created document" do
          expect(band).to be_persisted
        end

        it "sets the criteria attributes" do
          expect(band.name).to eq("Depeche Mode")
        end

        it "sets the attributes passed to build" do
          expect(band.genres).to eq([ "electro" ])
        end
      end
    end
  end

  describe "#create!" do

    let(:criteria) do
      Account.where(number: "11123213")
    end

    context "when provided invalid attributes" do

      it "raises an error" do
        expect {
          criteria.create!
        }.to raise_error(Mongoid::Errors::Validations)
      end
    end
  end

  [ :delete, :delete_all, :destroy, :destroy_all ].each do |method|

    describe "##{method}" do

      let(:name) do
        Name.new(first_name: "Durran")
      end

      let(:address_one) do
        Address.new(street: "Forsterstr")
      end

      let(:address_two) do
        Address.new(street: "Hobrechtstr")
      end

      before do
        Person.create(title: "Madam")
        2.times do |n|
          Person.create(
            title: "Sir",
            name: name,
            addresses: [ address_one, address_two ]
          )
        end
      end

      context "when removing root documents" do

        let(:criteria) do
          Person.where(title: "Sir", :age.gt => 5)
        end

        let!(:removed) do
          criteria.send(method)
        end

        it "deletes the removes the documents from the database" do
          expect(Person.count).to eq(1)
        end

        it "returns the number removed" do
          expect(removed).to eq(2)
        end
      end

      context "when removing embedded documents" do

        context "when removing a single document" do

          let(:person) do
            Person.where(title: "Sir").first
          end

          let(:criteria) do
            person.addresses.where(street: "Forsterstr")
          end

          let!(:removed) do
            criteria.send(method)
          end

          it "deletes the removes the documents from the database" do
            expect(person.addresses.count).to eq(1)
          end

          it "returns the number removed" do
            expect(removed).to eq(1)
          end
        end

        context "when removing multiple documents" do

          let(:person) do
            Person.where(title: "Sir").first
          end

          let(:criteria) do
            person.addresses.where(city: nil)
          end

          let!(:removed) do
            criteria.send(method)
          end

          it "deletes the removes the documents from the database" do
            expect(person.addresses.count).to eq(0)
          end

          it "returns the number removed" do
            expect(removed).to eq(2)
          end
        end
      end
    end
  end

  describe ".find_or_create_by" do

    context "when the document is found" do

      context "when providing an attribute" do

        let!(:person) do
          Person.create(title: "Senior")
        end

        it "returns the document" do
          expect(Person.find_or_create_by(title: "Senior")).to eq(person)
        end
      end

      context "when providing a document" do

        context "with an owner with a BSON identity type" do

          let!(:person) do
            Person.create
          end

          let!(:game) do
            Game.create(person: person)
          end

          context "when providing the object directly" do

            let(:from_db) do
              Game.find_or_create_by(person: person)
            end

            it "returns the document" do
              expect(from_db).to eq(game)
            end
          end

          context "when providing the proxy relation" do

            let(:from_db) do
              Game.find_or_create_by(person: game.person)
            end

            it "returns the document" do
              expect(from_db).to eq(game)
            end
          end
        end

        context "with an owner with an Integer identity type" do

          let!(:jar) do
            Jar.create
          end

          let!(:cookie) do
            Cookie.create(jar: jar)
          end

          let(:from_db) do
            Cookie.find_or_create_by(jar: jar)
          end

          it "returns the document" do
            expect(from_db).to eq(cookie)
          end
        end
      end
    end

    context "when the document is not found" do

      context "when providing a document" do

        let!(:person) do
          Person.create
        end

        let!(:game) do
          Game.create
        end

        let(:from_db) do
          Game.find_or_create_by(person: person)
        end

        it "returns the new document" do
          expect(from_db.person).to eq(person)
        end

        it "does not return an existing false document" do
          expect(from_db).to_not eq(game)
        end
      end

      context "when not providing a block" do

        let!(:person) do
          Person.find_or_create_by(title: "Senorita")
        end

        it "creates a persisted document" do
          expect(person).to be_persisted
        end

        it "sets the attributes" do
          expect(person.title).to eq("Senorita")
        end
      end

      context "when providing a block" do

        let!(:person) do
          Person.find_or_create_by(title: "Senorita") do |person|
            person.pets = true
          end
        end

        it "creates a persisted document" do
          expect(person).to be_persisted
        end

        it "sets the attributes" do
          expect(person.title).to eq("Senorita")
        end

        it "calls the block" do
          expect(person.pets).to be true
        end
      end
    end
  end

  describe ".find_or_create_by!" do

    context "when the document is found" do

      context "when providing an attribute" do

        let!(:person) do
          Person.create(title: "Senior")
        end

        it "returns the document" do
          expect(Person.find_or_create_by!(title: "Senior")).to eq(person)
        end
      end

      context "when providing a document" do

        context "with an owner with a BSON identity type" do

          let!(:person) do
            Person.create
          end

          let!(:game) do
            Game.create(person: person)
          end

          context "when providing the object directly" do

            let(:from_db) do
              Game.find_or_create_by!(person: person)
            end

            it "returns the document" do
              expect(from_db).to eq(game)
            end
          end

          context "when providing the proxy relation" do

            let(:from_db) do
              Game.find_or_create_by!(person: game.person)
            end

            it "returns the document" do
              expect(from_db).to eq(game)
            end
          end
        end

        context "with an owner with an Integer identity type" do

          let!(:jar) do
            Jar.create
          end

          let!(:cookie) do
            Cookie.create(jar: jar)
          end

          let(:from_db) do
            Cookie.find_or_create_by!(jar: jar)
          end

          it "returns the document" do
            expect(from_db).to eq(cookie)
          end
        end
      end
    end

    context "when the document is not found" do

      context "when providing a document" do

        let!(:person) do
          Person.create
        end

        let!(:game) do
          Game.create
        end

        let(:from_db) do
          Game.find_or_create_by!(person: person)
        end

        it "returns the new document" do
          expect(from_db.person).to eq(person)
        end

        it "does not return an existing false document" do
          expect(from_db).to_not eq(game)
        end
      end

      context "when not providing a block" do

        let!(:person) do
          Person.find_or_create_by!(title: "Senorita")
        end

        it "creates a persisted document" do
          expect(person).to be_persisted
        end

        it "sets the attributes" do
          expect(person.title).to eq("Senorita")
        end
      end

      context "when validation fails" do

        before do
          Person.validates_presence_of(:title)
        end

        after do
          Person.reset_callbacks(:validate)
        end

        it "raises an exception" do
          expect {
            Person.find_or_create_by!(ssn: "test")
          }.to raise_error(Mongoid::Errors::Validations)
        end
      end

      context "when providing a block" do

        let!(:person) do
          Person.find_or_create_by!(title: "Senorita") do |person|
            person.pets = true
          end
        end

        it "creates a persisted document" do
          expect(person).to be_persisted
        end

        it "sets the attributes" do
          expect(person.title).to eq("Senorita")
        end

        it "calls the block" do
          expect(person.pets).to be true
        end
      end
    end
  end

  describe ".find_or_initialize_by" do

    context "when the document is found" do

      let!(:person) do
        Person.create(title: "Senior")
      end

      it "returns the document" do
        expect(Person.find_or_initialize_by(title: "Senior")).to eq(person)
      end
    end

    context "when the document is not found" do

      context "when not providing a block" do

        let!(:person) do
          Person.find_or_initialize_by(title: "Senorita")
        end

        it "creates a new document" do
          expect(person).to be_new_record
        end

        it "sets the attributes" do
          expect(person.title).to eq("Senorita")
        end
      end

      context "when providing a block" do

        let!(:person) do
          Person.find_or_initialize_by(title: "Senorita") do |person|
            person.pets = true
          end
        end

        it "creates a new document" do
          expect(person).to be_new_record
        end

        it "sets the attributes" do
          expect(person.title).to eq("Senorita")
        end

        it "calls the block" do
          expect(person.pets).to be true
        end
      end
    end
  end

  describe "first_or_create" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    context "when the document is found" do

      let(:found) do
        Band.where(name: "Depeche Mode").first_or_create
      end

      it "returns the document" do
        expect(found).to eq(band)
      end
    end

    context "when the document is not found" do

      context "when attributes are provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_create(origin: "Essex")
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a persisted document" do
          expect(document).to be_persisted
        end

        it "sets the additional attributes" do
          expect(document.origin).to eq("Essex")
        end
      end

      context "when attributes are not provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_create
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a persisted document" do
          expect(document).to be_persisted
        end
      end

      context "when the criteria is on an embedded relation" do

        let!(:band) do
          Band.create(name: "Placebo")
        end

        let(:document) do
          band.notes.permanent.first_or_create(text: "test")
        end

        it "returns a new document" do
          expect(document.text).to eq("test")
        end

        it "returns a persisted document" do
          expect(document).to be_persisted
        end
      end

      context "when a block is provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_create do |doc|
            doc.active = false
          end
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a persisted document" do
          expect(document).to be_persisted
        end

        it "yields to the block" do
          expect(document.active).to be false
        end
      end

      context "when the criteria is complex" do

        context "when the document is not found" do

          let(:document) do
            Band.in(name: [ "New Order" ]).first_or_create(active: false)
          end

          it "returns a new document" do
            expect(document.active).to be false
          end

          it "returns a persisted document" do
            expect(document).to be_persisted
          end
        end
      end

      context 'when the criteria selector includes a hash field' do

        let(:document) do
          Person.where(map: { foo: :bar }).first_or_create
        end

        it 'sets the hash field' do
          expect(document.map).to eq({ foo: :bar })
        end
      end
    end
  end

  describe "first_or_create!" do

    context "when validation fails on the new document" do

      it "raises an error" do
        expect {
          Account.where(number: "12345").first_or_create!
        }.to raise_error(Mongoid::Errors::Validations)
      end
    end

    context "when passing a block" do

      let(:account) do
        Account.where(number: "12345").first_or_create! do |account|
          account.name = "testing"
        end
      end

      it "passes the block to the create call" do
        expect(account.name).to eq("testing")
      end

      it "persists the new document" do
        expect(account).to be_persisted
      end
    end

    context "when the document is found" do

      let!(:band) do
        Band.create!(name: "Depeche Mode")
      end

      let(:found) do
        Band.where(name: "Depeche Mode").first_or_create!
      end

      it "returns the document" do
        expect(found).to eq(band)
      end
    end

    context "when the document is not found" do

      let!(:band) do
        Band.create!(name: "Depeche Mode")
      end

      context "when attributes are provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_create!(origin: "Essex")
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a persisted document" do
          expect(document).to be_persisted
        end

        it "sets the additional attributes" do
          expect(document.origin).to eq("Essex")
        end
      end

      context "when attributes are not provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_create!
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a persisted document" do
          expect(document).to be_persisted
        end
      end

      context "when a block is provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_create! do |doc|
            doc.active = false
          end
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a persisted document" do
          expect(document).to be_persisted
        end

        it "yields to the block" do
          expect(document.active).to be false
        end
      end

      context "when the criteria is complex" do

        context "when the document is not found" do

          let(:document) do
            Band.in(name: [ "New Order" ]).first_or_create!(active: false)
          end

          it "returns a new document" do
            expect(document.active).to be false
          end

          it "returns a persisted document" do
            expect(document).to be_persisted
          end
        end
      end

      context 'when the criteria selector includes a hash field' do

        let(:document) do
          Person.where(map: { foo: :bar }).first_or_create
        end

        it 'sets the hash field' do
          expect(document.map).to eq({ foo: :bar })
        end
      end
    end
  end

  describe "first_or_initialize" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    context "when the document is found" do

      let(:found) do
        Band.where(name: "Depeche Mode").first_or_initialize
      end

      it "returns the document" do
        expect(found).to eq(band)
      end
    end

    context "when the document is not found" do

      context "when attributes are provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_initialize(origin: "Essex")
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a non persisted document" do
          expect(document).to_not be_persisted
        end

        it "sets the additional attributes" do
          expect(document.origin).to eq("Essex")
        end
      end

      context "when attributes are not provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_initialize
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a non persisted document" do
          expect(document).to_not be_persisted
        end
      end

      context "when a block is provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_initialize do |doc|
            doc.active = false
          end
        end

        it "returns a new document" do
          expect(document.name).to eq("Tool")
        end

        it "returns a non persisted document" do
          expect(document).to_not be_persisted
        end

        it "yields to the block" do
          expect(document.active).to be false
        end
      end

      context "when the criteria is complex" do

        context "when the document is not found" do

          let(:document) do
            Band.in(name: [ "New Order" ]).first_or_initialize(active: false)
          end

          it "returns a new document" do
            expect(document.active).to be false
          end

          it "returns a non persisted document" do
            expect(document).to_not be_persisted
          end
        end
      end
    end
  end

  describe "#update" do

    let!(:person) do
      Person.create!(title: "Sir")
    end

    let!(:address_one) do
      person.addresses.create(street: "Oranienstr")
    end

    let!(:address_two) do
      person.addresses.create(street: "Wienerstr")
    end

    context "when updating the root document" do

      context "when updating with a criteria" do

        before do
          Person.where(title: "Sir").update(title: "Madam")
        end

        it "updates all the matching documents" do
          expect(person.reload.title).to eq("Madam")
        end
      end

      context "when updating all directly" do

        before do
          Person.update(title: "Madam")
        end

        it "updates all the matching documents" do
          expect(person.reload.title).to eq("Madam")
        end
      end
    end

    context "when updating an embedded document" do

      before do
        Person.where(title: "Sir").update(
          "addresses.0.city" => "Berlin"
        )
      end

      let!(:from_db) do
        Person.first
      end

      it "updates all the matching documents" do
        expect(from_db.addresses.first.city).to eq("Berlin")
      end

      it "does not update non matching documents" do
        expect(from_db.addresses.last.city).to be_nil
      end
    end

    context "when updating a relation" do

      context "when the relation is an embeds many" do

        let(:from_db) do
          Person.first
        end

        context "when updating the relation directly" do

          before do
            person.addresses.update(city: "London")
          end

          it "updates the first document" do
            expect(from_db.addresses.first.city).to eq("London")
          end

          it "does not update the last document" do
            expect(from_db.addresses.last.city).to be_nil
          end
        end

        context "when updating the relation through a criteria" do

          before do
            person.addresses.where(street: "Oranienstr").update(city: "Berlin")
          end

          it "updates the matching documents" do
            expect(from_db.addresses.first.city).to eq("Berlin")
          end

          it "does not update non matching documents" do
            expect(from_db.addresses.last.city).to be_nil
          end
        end
      end

      context "when the relation is a references many" do

        before do
          person.posts.create!(title: "First")
          person.posts.create!(title: "Second")
        end

        context "when updating the relation directly" do

          before do
            person.posts.update(title: "London")
          end

          let(:from_db) do
            Person.first
          end

          it "updates the first document" do
            expect(from_db.posts.map(&:title)).to eq(["London", "Second"])
          end

          it "does not update the last document" do
            expect(from_db.posts[1].title).to eq("Second")
          end
        end

        context "when updating the relation through a criteria" do

          before do
            person.posts.where(title: "First").update(title: "Berlin")
          end

          let!(:from_db) do
            Person.first
          end

          it "updates the matching documents" do
            expect(from_db.posts.where(title: "Berlin").count).to eq(1)
          end

          it "does not update non matching documents" do
            expect(from_db.posts.where(title: "Second").count).to eq(1)
          end
        end
      end

      context "when the relation is a references many to many" do

        let(:from_db) do
          Person.first
        end

        let!(:preference_one) do
          person.preferences.create(name: "First")
        end

        let!(:preference_two) do
          person.preferences.create(name: "Second")
        end

        context "when updating the relation directly" do

          before do
            person.preferences.update(name: "London")
          end

          it "updates the first document" do
            expect(from_db.preferences[0].name).to eq("London")
          end

          it "does not update the last document" do
            expect(from_db.preferences[1].name).to eq("Second")
          end
        end

        context "when updating the relation through a criteria" do

          before do
            person.preferences.where(name: "First").update(name: "Berlin")
          end

          it "updates the matching documents" do
            expect(from_db.preferences[0].name).to eq("Berlin")
          end

          it "does not update non matching documents" do
            expect(from_db.preferences[1].name).to eq("Second")
          end
        end
      end
    end
  end

  describe "#update_all" do

    let!(:person) do
      Person.create(title: "Sir")
    end

    let!(:address_one) do
      person.addresses.create(street: "Oranienstr")
    end

    let!(:address_two) do
      person.addresses.create(street: "Wienerstr")
    end

    context "when updating the root document" do

      context "when updating with a criteria" do

        let(:from_db) do
          Person.first
        end

        before do
          Person.where(title: "Sir").update_all(title: "Madam")
        end

        it "updates all the matching documents" do
          expect(from_db.title).to eq("Madam")
        end
      end

      context "when updating all directly" do

        let(:from_db) do
          Person.first
        end

        before do
          Person.update_all(title: "Madam")
        end

        it "updates all the matching documents" do
          expect(from_db.title).to eq("Madam")
        end
      end
    end

    context "when updating an embedded document" do

      before do
        Person.where(title: "Sir").update_all(
          "addresses.0.city" => "Berlin"
        )
      end

      let!(:from_db) do
        Person.first
      end

      it "updates all the matching documents" do
        expect(from_db.addresses.first.city).to eq("Berlin")
      end

      it "does not update non matching documents" do
        expect(from_db.addresses.last.city).to be_nil
      end
    end

    context "when updating a relation" do

      context "when the relation is an embeds many" do

        let(:from_db) do
          Person.first
        end

        context "when updating the relation directly" do

          before do
            person.addresses.update_all(city: "London")
          end

          it "updates the first document" do
            expect(from_db.addresses.first.city).to eq("London")
          end

          it "updates the last document" do
            expect(from_db.addresses.last.city).to eq("London")
          end
        end

        context "when updating the relation through a criteria" do

          before do
            person.addresses.where(street: "Oranienstr").update_all(city: "Berlin")
          end

          it "updates the matching documents" do
            expect(from_db.addresses.first.city).to eq("Berlin")
          end

          it "does not update non matching documents" do
            expect(from_db.addresses.last.city).to be_nil
          end
        end
      end

      context "when the relation is a references many" do

        let!(:post_one) do
          person.posts.create(title: "First")
        end

        let!(:post_two) do
          person.posts.create(title: "Second")
        end

        context "when updating the relation directly" do

          before do
            person.posts.update_all(title: "London")
          end

          let!(:from_db) do
            Person.first
          end

          it "updates the first document" do
            expect(from_db.posts.first.title).to eq("London")
          end

          it "updates the last document" do
            expect(from_db.posts.last.title).to eq("London")
          end
        end

        context "when updating the relation through a criteria" do

          before do
            person.posts.where(title: "First").update_all(title: "Berlin")
          end

          let!(:from_db) do
            Person.first
          end

          it "updates the matching documents" do
            expect(from_db.posts.where(title: "Berlin").count).to eq(1)
          end

          it "does not update non matching documents" do
            expect(from_db.posts.where(title: "Second").count).to eq(1)
          end
        end
      end

      context "when the relation is a references many to many" do

        let(:from_db) do
          Person.first
        end

        let!(:preference_one) do
          person.preferences.create(name: "First")
        end

        let!(:preference_two) do
          person.preferences.create(name: "Second")
        end

        context "when updating the relation directly" do

          before do
            person.preferences.update_all(name: "London")
          end

          it "updates the first document" do
            expect(from_db.preferences.first.name).to eq("London")
          end

          it "updates the last document" do
            expect(from_db.preferences.last.name).to eq("London")
          end
        end

        context "when updating the relation through a criteria" do

          before do
            person.preferences.where(name: "First").update_all(name: "Berlin")
          end

          it "updates the matching documents" do
            expect(from_db.preferences[0].name).to eq("Berlin")
          end

          it "does not update non matching documents" do
            expect(from_db.preferences[1].name).to eq("Second")
          end
        end
      end
    end
  end

  describe '#create_with' do

    context 'when called on the class' do

      let(:attrs) do
        { 'username' => 'Turnip' }
      end

      it 'returns a criteria with the defined attributes' do
        expect(Person.create_with(attrs).selector).to eq(attrs)
      end

      context 'when a method is chained' do

        context 'when a write method is chained' do

          it 'executes the method' do
            expect(Person.create_with(attrs).new.username).to eq('Turnip')
          end
        end

        context 'when a write method is chained' do

          let(:query) do
            { 'age' => 50 }
          end

          let(:new_person) do
            Person.create_with(attrs).find_or_create_by(query)
          end

          it 'executes the write' do
            expect(new_person.username).to eq('Turnip')
            expect(new_person.age).to eq(50)
          end

          context 'when the attributes are shared with the write method args' do

            let(:query) do
              { 'username' => 'Beet', 'age' => 50 }
            end

            let(:new_person) do
              Person.create_with(attrs).find_or_create_by(query)
            end

            it 'gives the write method args precedence' do
              #  @todo: uncomment when MONGOID-4193 is closed
              #expect(new_person.username).to eq('Beet')
              expect(new_person.age).to eq(50)
            end
          end
        end
      end
    end

    context 'when called on a criteria' do

      let(:criteria_selector) do
        { 'username' => 'Artichoke', 'age' => 25 }
      end

      let(:criteria) do
        Person.where(criteria_selector)
      end

      context 'when the original criteria shares attributes with the attribute args' do

        context 'when all the original attributes are shared with the new attributes' do

          let(:attrs) do
            { 'username' => 'Beet', 'age' => 50 }
          end

          it 'overwrites all the original attributes' do
            expect(criteria.create_with(attrs).selector).to eq(attrs)
          end
        end
      end

      context 'when only some of the original attributes are shared with the attribute args' do

        let(:attrs) do
          { 'username' => 'Beet' }
        end

        it 'only overwrites the shared attributes' do
          expect(criteria.create_with(attrs).selector).to eq(criteria_selector.merge!(attrs))
        end
      end

      context 'when a method is chained' do

        let(:attrs) do
          { 'username' => 'Turnip' }
        end

        let(:query) do
          { 'username' => 'Beet', 'age' => 50 }
        end

        context 'when a write method is chained' do

          it 'executes the method' do
            #  @todo: uncomment when MONGOID-4193 is closed
            #expect(criteria.create_with(attrs).new.username).to eq('Beet')
            expect(criteria.create_with(attrs).new.age).to eq(25)
          end
        end

        context 'when a write method is chained' do

          let(:new_person) do
            criteria.create_with(attrs).find_or_create_by(query)
          end

          it 'executes the query' do
            #  @todo: uncomment when MONGOID-4193 is closed
            #expect(new_person.username).to eq('Beet')
            #expect(new_person.age).to eq(50)
          end
        end
      end
    end
  end
end
