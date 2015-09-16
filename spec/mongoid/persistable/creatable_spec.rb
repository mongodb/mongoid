require "spec_helper"

describe Mongoid::Persistable::Creatable do

  describe ".create" do

    context "when provided an array of attributes" do

      context "when no block is passed" do

        let(:people) do
          Person.create([{ title: "sir" }, { title: "madam" }])
        end

        it "creates the first document" do
          expect(people.first.title).to eq("sir")
        end

        it "persists the first document" do
          expect(people.first).to be_persisted
        end

        it "creates the second document" do
          expect(people.last.title).to eq("madam")
        end

        it "persists the second document" do
          expect(people.last).to be_persisted
        end
      end

      context "when no block is passed" do

        let(:people) do
          Person.create([{ title: "sir" }, { title: "madam" }]) do |person|
            person.age = 36
          end
        end

        it "creates the first document" do
          expect(people.first.title).to eq("sir")
        end

        it "persists the first document" do
          expect(people.first).to be_persisted
        end

        it "passes the block to the first document" do
          expect(people.first.age).to eq(36)
        end

        it "creates the second document" do
          expect(people.last.title).to eq("madam")
        end

        it "persists the second document" do
          expect(people.last).to be_persisted
        end

        it "passes the block to the second document" do
          expect(people.last.age).to eq(36)
        end
      end
    end

    context "when providing attributes" do

      let(:person) do
        Person.create(title: "Sensei")
      end

      it "it saves the document" do
        expect(person).to be_persisted
      end

      it "returns the document" do
        expect(person).to be_a_kind_of(Person)
      end

      context "when creating an embedded document" do

        let(:address) do
          Address.create(addressable: person)
        end

        it "persists the document" do
          expect(address).to be_persisted
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
          expect(document.keys).to_not include("addresses")
        end

        it "should persist on user_addesses key on User document" do
          expect(document.keys).to include("user_adresses")
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
        expect(person.ssn).to eq("666-66-6666")
      end

      it "persists the document" do
        expect(person).to be_persisted
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
        expect(attributes["version"]).to eq(3)
      end

      it "persists the type" do
        expect(attributes["_type"]).to eq("Browser")
      end

      it "persists the attributes" do
        expect(attributes["name"]).to eq("Test")
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
        expect(attributes["version"]).to eq(2)
      end

      it "persists the type" do
        expect(attributes["_type"]).to eq("Firefox")
      end

      it "persists the attributes" do
        expect(attributes["name"]).to eq("Testy")
      end

      it "returns the document when querying for superclass" do
        expect(Browser.where(name: "Testy").first).to eq(firefox)
      end

      it "returns the document when querying for root class" do
        expect(Canvas.where(name: "Testy").first).to eq(firefox)
      end

      it "returnss on of this subclasses if you find by _type" do
        expect(Canvas.where(:_type.in => ['Firefox']).count).to eq(1)
      end
    end

    context "when the document is subclassed" do

      let!(:firefox) do
        Firefox.create(name: "firefox")
      end

      it "finds the document with String args" do
        expect(Firefox.find(firefox.id.to_s)).to eq(firefox)
      end

      context "when querying for parent documents" do

        let(:canvas) do
          Canvas.where(name: "firefox").first
        end

        it "returns matching subclasses" do
          expect(canvas).to eq(firefox)
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
        expect(from_db.palette.tools.map(&:class)).to eq([Pencil, Eraser])
      end
    end

    context "when creating references_many documents from a parent association" do

      let!(:container) do
        ShippingContainer.create
      end

      let(:driver) do
        Driver.create
      end

      it "does not bleed relations from one subclass to another" do
        expect(Truck.relations.keys).to eq(%w/ shipping_container driver bed /)
        expect(Car.relations.keys).to eq(%w/ shipping_container driver /)
      end

      context "when appending new documents" do

        before do
          container.vehicles << Car.new
          container.vehicles << Truck.new
        end

        it "allows STI from << using model.new" do
          expect(container.vehicles.map(&:class)).to eq([ Car, Truck ])
        end
      end

      context "when appending persisted documents" do

        before do
          container.vehicles << Car.create
          container.vehicles << Truck.create
        end

        it "allows STI from << using model.create" do
          expect(container.vehicles.map(&:class)).to eq([ Car, Truck ])
        end
      end

      context "when building related documents" do

        before do
          container.vehicles.build({}, Car).save
          container.vehicles.build({}, Truck).save
        end

        it "allows STI from the build call" do
          expect(container.vehicles.map(&:class)).to eq([ Car, Truck ])
        end
      end

      context "when building with a type attribute" do

        before do
          container.vehicles.build({ "_type" => "Car" })
          container.vehicles.build({ "_type" => "Truck" })
        end

        it "respects the _type attribute from the build call" do
          expect(container.vehicles.map(&:class)).to eq([ Car, Truck ])
        end
      end

      context "when creating related documents" do

        before do
          container.vehicles.create({}, Car)
          container.vehicles.create({}, Truck)
        end

        it "allows STI from the create call" do
          expect(container.vehicles.map(&:class)).to eq([ Car, Truck ])
        end
      end

      context "when creating with a type attribute" do

        before do
          container.vehicles.create({ "_type" => "Car" })
          container.vehicles.create({ "_type" => "Truck" })
        end

        it "respects the _type attribute from the create call" do
          expect(container.vehicles.map(&:class)).to eq([ Car, Truck ])
        end
      end

      context "#find_or_initialize_by" do

        before do
          container.vehicles.find_or_initialize_by({ driver_id: driver.id }, Car)
        end

        it "initializes the given type document" do
          expect(container.vehicles.map(&:class)).to eq([ Car ])
        end

        it "initializes with the given attributes" do
          expect(container.vehicles.map(&:driver)).to eq([ driver ])
        end
      end

      context "#find_or_create_by" do

        before do
          container.vehicles.find_or_create_by({ driver_id: driver.id }, Car)
        end

        it "creates the given type document" do
          expect(container.vehicles.map(&:class)).to eq([ Car ])
        end

        it "creates with the given attributes" do
          expect(container.vehicles.map(&:driver)).to eq([ driver ])
        end

        it "creates the correct number of documents" do
          expect(container.vehicles.size).to eq(1)
        end

        context "when executing with a found document" do

          before do
            container.vehicles.find_or_create_by({ driver_id: driver.id }, Car)
          end

          it "does not create an additional document" do
            expect(container.vehicles.size).to eq(1)
          end
        end

        context "when executing with an additional new document" do

          before do
            container.vehicles.find_or_create_by({ driver_id: driver.id }, Truck)
          end

          it "creates the new additional document" do
            expect(container.vehicles.size).to eq(2)
          end
        end

        context 'when searching by a Time value' do

          let!(:account) do
            Account.create!(name: 'test', period_started_at: Time.now.utc)
          end

          let!(:queried_consumption) do
            account.consumption_periods.find_or_create_by(started_at: account.period_started_at)
          end

          before do
            account.reload
          end

          it 'does not change the Time value' do
            expect(queried_consumption).to eq(account.current_consumption)
          end
        end
      end

      context "#find_or_create_by!" do

        before do
          container.vehicles.find_or_create_by!({ driver_id: driver.id }, Car)
        end

        it "creates the given type document" do
          expect(container.vehicles.map(&:class)).to eq([ Car ])
        end

        it "creates with the given attributes" do
          expect(container.vehicles.map(&:driver)).to eq([ driver ])
        end

        it "creates the correct number of documents" do
          expect(container.vehicles.size).to eq(1)
        end

        context "when executing with a found document" do

          before do
            container.vehicles.find_or_create_by!({ driver_id: driver.id }, Car)
          end

          it "does not create an additional document" do
            expect(container.vehicles.size).to eq(1)
          end
        end

        context "when executing with an additional new document" do

          before do
            container.vehicles.find_or_create_by!({ driver_id: driver.id }, Truck)
          end

          it "creates the new additional document" do
            expect(container.vehicles.size).to eq(2)
          end
        end
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
          expect(people.first.title).to eq("sir")
        end

        it "persists the first document" do
          expect(people.first).to be_persisted
        end

        it "creates the second document" do
          expect(people.last.title).to eq("madam")
        end

        it "persists the second document" do
          expect(people.last).to be_persisted
        end
      end

      context "when no block is passed" do

        let(:people) do
          Person.create!([{ title: "sir" }, { title: "madam" }]) do |person|
            person.age = 36
          end
        end

        it "creates the first document" do
          expect(people.first.title).to eq("sir")
        end

        it "persists the first document" do
          expect(people.first).to be_persisted
        end

        it "passes the block to the first document" do
          expect(people.first.age).to eq(36)
        end

        it "creates the second document" do
          expect(people.last.title).to eq("madam")
        end

        it "persists the second document" do
          expect(people.last).to be_persisted
        end

        it "passes the block to the second document" do
          expect(people.last.age).to eq(36)
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
            4.times { Person.create!(ssn: "555-55-1029") }
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
        expect(person.ssn).to eq("666-66-6666")
      end

      it "persists the document" do
        expect(person).to be_persisted
      end
    end

    context "when setting the composite key" do

      let(:account) do
        Account.create!(name: "Hello")
      end

      it "saves the document" do
        expect(account).to be_persisted
      end
    end

    context "when a callback returns false" do

      it "raises a callback error" do
        expect { Oscar.create! }.to raise_error(Mongoid::Errors::Callback)
      end
    end
  end
end
