require "spec_helper"

describe Mongoid::Persistence do

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
          expect(deleted).to be_true
        end

        it "resets the flagged for destroy flag" do
          expect(person).to_not be_flagged_for_destroy
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
            expect(person.addresses).to be_empty
          end

          it "removes the attributes from the parent" do
            expect(person.raw_attributes["addresses"]).to be_nil
          end

          it "resets the flagged for destroy flag" do
            expect(address).to_not be_flagged_for_destroy
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
            expect(from_db.addresses).to be_empty
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
            expect(from_db.addresses.first.locations).to be_empty
          end

          it "resets the flagged for destroy flag" do
            expect(location).to_not be_flagged_for_destroy
          end
        end
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
          expect(account.errors[:nickname]).to_not be_empty
        end

        it "does not upsert the document" do
          expect(account).to be_a_new_record
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
          expect(existing.reload.name).to eq("Tool")
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
          expect(insert.reload).to eq(insert)
        end

        it "does not modify any fields" do
          expect(insert.reload.name).to eq("Tool")
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
          expect(existing.reload.name).to eq("Depeche Mode")
        end

        it "returns true" do
          expect(upsert).to be_true
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
          expect(Person.count).to eq(0)
        end

        it "returns the number of documents removed" do
          expect(removed).to eq(1)
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
            expect(Person.count).to eq(1)
          end

          it "returns the number of documents removed" do
            expect(removed).to eq(1)
          end
        end

        context "when no conditions attribute provided" do

          let!(:removed) do
            Person.send(method, title: "sir")
          end

          it "removes the matching documents" do
            expect(Person.count).to eq(1)
          end

          it "returns the number of documents removed" do
            expect(removed).to eq(1)
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
      expect(user.changes["last_login"].last.class).to eq(Time)
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
      expect(user.changes["account_expires"].last.class).to eq(Time)
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
        expect(person.save).to be_true
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
        expect(game.reload.person_id).to be_blank
      end
    end

    context "when value is a populated string" do

      before do
        game.person_id = person.id.to_s
        game.save
      end

      it "sets the foreign key as ObjectID" do
        expect(game.reload.person_id).to eq(person.id)
      end
    end

    context "when value is a ObjectID" do

      before do
        game.person_id = person.id
        game.save
      end

      it "keeps the the foreign key as ObjectID" do
        expect(game.reload.person_id).to eq(person.id)
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

    it 'returnss on of this subclasses if you find by _type' do
      expect(Canvas.where(:_type.in => ['Firefox']).count).to eq(1)
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
      expect(from_db).to be_a_kind_of(Firefox)
    end

    it "properly persists the one-to-one relations" do
      expect(from_db.writer).to eq(writer)
    end

    it "properly persists the one-to-many type" do
      expect(from_db.shapes.first).to eq(circle)
    end

    it "properly persists the one-to-many relations" do
      expect(from_db.shapes.last).to eq(square)
    end

    it "properly sets up the parent relation" do
      expect(from_db.shapes.first).to eq(circle)
    end

    it "properly sets up the entire hierarchy" do
      expect(from_db.shapes.first.canvas).to eq(firefox)
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
        expect(Canvas.count).to eq(3)
      end

      it "returns correct counts for child classes" do
        expect(Firefox.count).to eq(1)
      end

      it "returns correct counts for root subclasses" do
        expect(Browser.count).to eq(2)
      end
    end

    context "when deleting all documents" do

      before do
        Firefox.delete_all
      end

      it "deletes from the parent class collection" do
        expect(Canvas.count).to eq(2)
      end

      it "returns correct counts for child classes" do
        expect(Firefox.count).to eq(0)
      end

      it "returns correct counts for root subclasses" do
        expect(Browser.count).to eq(1)
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

  context "Creating references_many documents from a parent association" do

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
    end
  end
end
