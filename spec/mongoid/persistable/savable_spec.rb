require "spec_helper"

describe Mongoid::Persistable::Savable do

  describe "#save" do

    let(:person) do
      Person.create
    end

    let(:contextable_item) do
      ContextableItem.new
    end

    let(:persisted_contextable_item) do
      ContextableItem.create(title: 'sir')
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
        person.addresses.create(city: "London")
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
          expect(person.atomic_updates).to eq({
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
            expect(person.title).to eq("King")
          end

          it "saves embedded many relations" do
            expect(person.addresses.first.street).to eq("Bond St")
          end

          it "saves embedded one relations" do
            expect(person.name.first_name).to eq("Ryan")
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
          expect(from_db.addresses[0].number).to eq(102)
        end

        it "saves modifications to new embedded docs" do
          expect(from_db.addresses[1].street).to eq('North Ave')
        end

        it "saves modifications to deeply embedded docs" do
          expect(from_db.addresses[0].locations.first.name).to eq('Work')
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

    context "when the document is readonly" do

      let(:person) do
        Person.only(:title).first
      end

      before do
        Person.create(title: "sir")
      end

      it "raises an error" do
        expect {
          person.save
        }.to raise_error(Mongoid::Errors::ReadonlyDocument)
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
          expect { person.save! }.to raise_error
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

    context "when the document is readonly" do

      let(:person) do
        Person.only(:title).first
      end

      before do
        Person.create(title: "sir")
      end

      it "raises an error" do
        expect {
          person.save!
        }.to raise_error(Mongoid::Errors::ReadonlyDocument)
      end
    end
  end
end
