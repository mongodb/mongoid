# frozen_string_literal: true

require "spec_helper"
require "support/immutable_ids"

describe Mongoid::Persistable::Savable do
  extend Mongoid::ImmutableIds
  immutable_id_examples_as "persisted _ids are immutable"

  describe "#save" do

    let(:person) do
      Person.create!
    end

    let(:contextable_item) do
      ContextableItem.new
    end

    let(:persisted_contextable_item) do
      ContextableItem.create!(title: 'sir')
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
          expect(saved).to be true
        end

        it "saves the document" do
          expect(account).to be_persisted
        end

        it "does not add any validation errors" do
          expect(account.errors).to be_empty
        end
      end

      context "when saving document that is a belongs to child" do

        let(:account) do
          Account.create!(name: 'Foobar')
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
              expect(alert.errors).to be_empty
            end

            context "when the document is not new" do

              before do
                alert.save(validate: false)
              end

              it "clears any errors off the document" do
                expect(alert.errors).to be_empty
              end
            end
          end
        end

        context 'when the embedded document is unchanged' do

          let(:kangaroo) do
            Kangaroo.new
          end

          after do
            Kangaroo.destroy_all
          end

          it 'only makes one call to the database' do
            allow(Kangaroo.collection).to receive(:insert).once
            expect_any_instance_of(Mongo::Collection::View).to receive(:update_one).never
            kangaroo.build_baby
            kangaroo.save
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
          expect(limited.changes).to be_empty
        end
      end

      context "when iterating over the documents" do

        let(:limited) do
          Person.only(:_id)
        end

        it "does not flag any changes" do
          limited.each do |person|
            expect(person.changes).to be_empty
          end
        end
      end
    end

    context "when validation passes" do

      it "returns true" do
        expect(person.save).to be true
      end
    end

    context "when validation fails" do

      let(:address) do
        person.addresses.create!(city: "London")
      end

      before do
        address.save
      end

      it "has the appropriate errors" do
        expect(address.errors[:street]).to eq(["can't be blank"])
      end
    end

    context "when modifying the entire hierarchy" do

      context "when performing modification and insert ops" do

        let(:owner) do
          Owner.create!(name: "Blah")
        end

        let!(:birthday) do
          owner.birthdays.build(title: "First")
        end

        let!(:scribe) do
          owner.create_scribe(name: "Josh")
        end

        let(:from_db) do
          Owner.find(owner.id)
        end

        before do
          owner.name = "King"
          scribe.name = "Tosh"
        end

        it "persists with proper set and push modifiers" do
          expect(owner.atomic_updates).to eq({
            "$set" => {
              "name" => "King",
              "scribe.name" => "Tosh"
            },
            "$push"=> {
              "birthdays" => { '$each' => [ { "_id" => birthday.id, "title" => "First" } ] }
            }
          })
        end

        context "when saving the document" do

          it "saves the root document" do
            expect(owner.name).to eq("King")
          end

          it "saves embedded many relations" do
            expect(owner.birthdays.first.title).to eq("First")
          end

          it "saves embedded one relations" do
            expect(owner.scribe.name).to eq("Tosh")
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
          Person.create!(
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
          expect(from_db.addresses[0].number).to eq(102)
        end

        it "saves modifications to new embedded docs" do
          expect(from_db.addresses[1].street).to eq('North Ave')
        end

        it "saves modifications to deeply embedded docs" do
          expect(from_db.addresses[0].locations.first.name).to eq('Work')
        end
      end

      context 'when adding documents to embedded associations on multiple levels' do
        let!(:truck) { Truck.create! }
        let!(:crate) { truck.crates.create!(volume: 0.4) }

        it 'persists the new documents' do
          expect(truck.crates.size).to eq 1
          expect(truck.crates[0].volume).to eq 0.4
          expect(truck.crates[0].toys.size).to eq 0

          truck.crates.first.toys.build(name: "Teddy bear")
          truck.crates.build(volume: 0.8)

          # The following is equivalent to the two lines above:
          #
          # truck.crates_attributes = {
          #   '0' => {
          #     "toys_attributes" => {
          #       "0" => {
          #         "name" => "Teddy bear"
          #       }
          #     },
          #     "id" => crate.id.to_s
          #   },
          #   "1" => {
          #     "volume" => 0.8
          #   }
          # }

          expect(truck.crates.size).to eq 2
          expect(truck.crates[0].volume).to eq 0.4
          expect(truck.crates[0].toys.size).to eq 1
          expect(truck.crates[0].toys[0].name).to eq "Teddy bear"
          expect(truck.crates[1].volume).to eq 0.8
          expect(truck.crates[1].toys.size).to eq 0

          # TODO: MONGOID-5026: combine the updates so that there are
          # no conflicts.
          #expect(truck.atomic_updates[:conflicts]).to eq nil

          expect { truck.save! }.not_to raise_error

          _truck = Truck.find(truck.id)
          expect(_truck.crates.size).to eq 2
          expect(_truck.crates[0].volume).to eq 0.4
          expect(_truck.crates[0].toys.size).to eq 1
          expect(_truck.crates[0].toys[0].name).to eq "Teddy bear"
          expect(_truck.crates[1].volume).to eq 0.8
          expect(_truck.crates[1].toys.size).to eq 0
        end
      end

      context 'when adding documents to embedded association and updating parent fields' do
        let!(:truck) { Truck.create! }
        let!(:crate) { truck.crates.create!(volume: 0.4) }

        it 'performs all writes' do
          truck.crates.build(volume: 1)
          truck.crates.first.volume = 2

          truck.save!

          _truck = Truck.find(truck.id)
          _truck.crates.length.should == 2
          _truck.crates.first.volume.should == 2
          _truck.crates.last.volume.should == 1
        end
      end

      context 'when adding documents to nested embedded association and updating first association fields' do
        let!(:truck) { Truck.create! }
        let!(:seat) { truck.seats.create!(rating: 1) }

        it 'performs all writes' do
          truck.seats.first.armrests.build(side: 'left')
          truck.seats.first.rating = 2

          truck.save!

          _truck = Truck.find(truck.id)
          _truck.seats.length.should == 1
          _truck.seats.first.armrests.length.should == 1
          _truck.seats.first.armrests.first.side.should == 'left'
        end
      end

      context 'when adding documents to nested embedded association and adding another top level association' do
        let!(:truck) { Truck.create! }
        let!(:crate) { truck.crates.create!(volume: 1) }

        it 'performs all writes' do
          truck.crates.first.toys.build(name: 'Bear')
          truck.crates.build

          truck.save!

          _truck = Truck.find(truck.id)
          _truck.crates.length.should == 2
          _truck.crates.first.toys.length.should == 1
          _truck.crates.first.toys.first.name.should == 'Bear'
          _truck.crates.last.toys.length.should == 0
        end

        context 'when also updating first embedded top level association' do
          it 'performs all writes' do
            truck.crates.first.volume = 2
            truck.crates.first.toys.build(name: 'Bear')
            truck.crates.build

            truck.save!

            _truck = Truck.find(truck.id)
            _truck.crates.length.should == 2
            _truck.crates.first.toys.length.should == 1
            _truck.crates.first.toys.first.name.should == 'Bear'
            _truck.crates.last.toys.length.should == 0
          end
        end
      end

      context 'when adding documents to embedded associations with cascaded callbacks on update' do
        let!(:truck) { Truck.create! }
        let!(:seat) { truck.seats.create!(rating: 1) }

        it 'persists the new documents' do
          expect(truck.seats.size).to eq 1
          expect(truck.seats[0].rating).to eq 1

          truck.seats.build

          expect { truck.save! }.not_to raise_error

          _truck = Truck.find(truck.id)
          expect(_truck.seats.size).to eq 2
          expect(_truck.seats[0].rating).to eq 1
          expect(_truck.seats[1].rating).to eq 100
        end

        context 'when embedded association embeds another association' do
          it 'persists the new documents' do
            expect(truck.seats.size).to eq 1
            expect(truck.seats[0].rating).to eq 1

            truck.seats.first.armrests.build
            truck.seats.build

            expect { truck.save! }.not_to raise_error

            _truck = Truck.find(truck.id)
            expect(_truck.seats.size).to eq 2
            expect(_truck.seats[0].rating).to eq 2
            expect(_truck.seats[0].armrests.length).to eq 1
            expect(_truck.seats[1].rating).to eq 100
          end
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
          expect(person.name).to be_nil
        end
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
          expect(person.save).to be true
        end
      end
    end

    context "when the changed attribute is not writable" do

      before do
        Person.create!(title: "sir")
      end

      let(:person) do
        Person.only(:title).first
      end

      it "raises an error" do
        expect {
          person.username = 'unloaded-attribute'
          person.save
        }.to raise_error(ActiveModel::MissingAttributeError)
      end

      context 'when the changed attribute is aliased' do

        before do
          Person.create!(at: Time.now)
        end

        let(:person) do
          Person.only(:at).first
        end

        it "saves the document" do
          person.aliased_timestamp = Time.now
          expect(person.save!(validate: false)).to be true
        end
      end
    end

    context "when validation context isn't assigned" do
      it "returns true" do
        expect(contextable_item.save).to be true
      end
    end

    context "when validation context exists" do

      context "on new document" do

        it "returns true" do
          contextable_item.title = "sir"
          expect(contextable_item.save(context: :in_context)).to be true
        end

        it "returns false" do
          expect(contextable_item.save(context: :in_context)).to be false
        end
      end

      context "on persisted document" do

        it "returns true" do
          persisted_contextable_item.title = "lady"
          expect(persisted_contextable_item.save(context: :in_context)).to be true
        end

        it "returns false" do
          persisted_contextable_item.title = nil
          expect(persisted_contextable_item.save(context: :in_context)).to be false
        end
      end
    end

    context "when saving a readonly document" do

      context "when legacy_readonly is true" do
        config_override :legacy_readonly, true

        context "when its a new document" do

          let(:document) do
            Band.new
          end

          before do
            document.__selected_fields = { 'test' => 1 }
            expect(document).to be_readonly
          end

          it "persists the document" do
            expect(Band.count).to eq(0)
            document.save!
            expect(Band.count).to eq(1)
          end
        end

        context "when its an old document" do

          let(:document) do
            Band.only(:name).first
          end

          before do
            Band.create!
            expect(document).to be_readonly
          end

          it "updates the document" do
            document.name = "The Rolling Stones"
            document.save!
            expect(Band.first.name).to eq("The Rolling Stones")
          end
        end
      end

      context "when legacy_readonly is false" do
        config_override :legacy_readonly, false

        context "when its a new document" do

          let(:document) do
            Band.new
          end

          before do
            document.readonly!
            expect(document).to be_readonly
          end

          it "raises a readonly error" do
            expect do
              document.save!
            end.to raise_error(Mongoid::Errors::ReadonlyDocument)
          end
        end

        context "when its an old document" do

          let(:document) do
            Band.first.tap(&:readonly!)
          end

          before do
            Band.create!
            expect(document).to be_readonly
          end

          it "raises a readonly error" do
            document.name = "The Rolling Stones"
            expect do
              document.save!
            end.to raise_error(Mongoid::Errors::ReadonlyDocument)
          end
        end
      end
    end

    context "when the _id has been modified" do
      def invoke_operation!
        object._id = new_id_value
        object.save
      end

      it_behaves_like "persisted _ids are immutable"
    end
  end

  describe "save!" do

    context "inserting with a field that is not unique" do

      context "when a unique index exists" do

        let(:person) do
          Person.new(ssn: "555-55-9999")
        end

        before do
          Person.index({ ssn: 1 }, { unique: true })
          Person.create_indexes
          Person.create!(ssn: "555-55-9999")
        end

        after do
          Person.collection.drop
        end

        it "raises an OperationFailure" do
          expect { person.save! }.to raise_error(Mongo::Error::OperationFailure)
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
        expect { service.save! }.to raise_error(Mongoid::Errors::Validations)
        expect { service.save! }.to raise_error(Mongoid::Errors::Validations)
      end
    end

    context "when a callback aborts the callback chain" do

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
        expect(oscar).to be_destroyed
      end
    end

    context "when a DateTime attribute is updated and persisted" do

      let(:user) do
        User.create!(last_login: 2.days.ago).tap do |u|
          u.last_login = DateTime.now
        end
      end

      it "reads for persistence as a UTC Time" do
        expect(user.changes["last_login"].last.class).to eq(Time)
      end

      it "persists with no exceptions thrown" do
        expect {
          user.save!
        }.not_to raise_error
      end
    end

    context "when a Date attribute is persisted" do

      let(:user) do
        User.create!(account_expires: 2.years.from_now).tap do |u|
          u.account_expires = "2/2/2002".to_date
        end
      end

      it "reads for persistence as a UTC Time" do
        expect(user.changes["account_expires"].last.class).to eq(Time)
      end

      it "persists with no exceptions thrown" do
        expect {
          user.save!
        }.not_to raise_error
      end
    end

    context "when the document has associations" do

      let!(:firefox) do
        Firefox.create!(name: "firefox")
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
  end
end
