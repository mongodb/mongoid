# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Reloadable do

  describe "#reload" do

    context 'when persistence options are set' do

      let(:person) do
        Person.with(collection: 'other') do |person_class|
          person_class.create!
        end
      end

      let(:reloaded) do
        Person.with(collection: 'other') do |person_class|
          person_class.first
        end
      end

      it 'applies the persistence options' do
        expect(person).to eq(reloaded)
      end
    end

    context "when using bson ids" do

      let(:person) do
        Person.create!
      end

      let!(:from_db) do
        Person.find(person.id).tap do |peep|
          peep.age = 35
          peep.save!
        end
      end

      it "reloads the object attributes from the db" do
        person.reload
        expect(person.age).to eq(35)
      end

      it "reload should return self" do
        expect(person.reload).to eq(from_db)
      end
    end

    context "when using string ids" do

      let(:account) do
        Account.create!(name: "bank", number: "1000")
      end

      let!(:from_db) do
        Account.find(account.id).tap do |acc|
          acc.number = "1001"
          acc.save!
        end
      end

      it "reloads the object attributes from the db" do
        account.reload
        expect(account.number).to eq("1001")
      end

      it "reload should return self" do
        expect(account.reload).to eq(from_db)
      end
    end

    context "when an after initialize callback is defined" do

      let!(:book) do
        Book.create!(title: "Snow Crash")
      end

      before do
        book.update_attribute(:chapters, 50)
        book.reload
      end

      it "runs the callback" do
        expect(book.chapters).to eq(5)
      end
    end

    context "when the document was dirty" do

      let(:person) do
        Person.create!
      end

      before do
        person.title = "Sir"
        person.reload
      end

      it "resets the dirty modifications" do
        expect(person.changes).to be_empty
      end

      it "resets attributes_before_type_cast" do
        expect(person.attributes_before_type_cast).to eq(person.attributes)
      end
    end

    context "when document not saved" do

      context "when there is no document matching our id" do

        it "raises an error" do
          expect {
            Person.new.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Person with id\(s\)/)
        end
      end

      context 'when there is a document matching our id' do

        let!(:previous) { Agent.create!(title: '007') }

        let(:agent) { Agent.new(id: previous.id) }

        it 'loads the existing document' do
          agent.title.should be nil

          lambda do
            agent.reload
          end.should_not raise_error

          agent.title.should == '007'
        end
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create!
      end

      context "when embedded a single level" do

        context 'when persistence options are set' do

          let(:person) do
            Person.with(collection: 'other') do |person_class|
              person_class.create!
            end
          end

          let!(:address) do
            person.with(collection: 'other') do |person_object|
              person_object.addresses.create!(street: "Abbey Road", number: 4)
            end
          end

          before do
            Person.mongo_client[:other].find(
                { "_id" => person.id }
            ).update_one({ "$set" => { "addresses.0.number" => 3 }})
          end

          let!(:reloaded) do
            person.with(collection: 'other') do |person_class|
              person.addresses.first.reload
            end
          end

          it "reloads the embedded document attributes" do
            expect(reloaded.number).to eq(3)
          end

        end

        context "when the relation is an embeds many" do

          let!(:address) do
            person.addresses.create!(street: "Abbey Road", number: 4)
          end

          before do
            Person.collection.find(
              { "_id" => person.id }
            ).update_one({ "$set" => { "addresses.0.number" => 3 }})
          end

          let!(:reloaded) do
            address.reload
          end

          it "reloads the embedded document attributes" do
            expect(reloaded.number).to eq(3)
          end

          it "reloads the reference on the parent" do
            expect(person.addresses.first).to eq(reloaded)
          end

          it "retains the relation to the parent" do
            expect(reloaded.addressable).to eq(person)
          end
        end

        context "when the relation is an embeds one" do

          let!(:name) do
            person.create_name(first_name: "Syd")
          end

          before do
            Person.collection.find({ "_id" => person.id }).
              update_one({ "$set" => { "name.last_name" => "Vicious" }})
          end

          let!(:reloaded) do
            name.reload
          end

          it "reloads the embedded document attributes" do
            expect(reloaded.last_name).to eq("Vicious")
          end

          it "reloads the reference on the parent" do
            expect(person.name).to eq(reloaded)
          end

          it "retains the relation to the parent" do
            expect(reloaded.namable).to eq(person)
          end
        end
      end

      context "when the relation is embedded multiple levels" do

        let!(:address) do
          person.addresses.create!(street: "Abbey Road", number: 3)
        end

        let!(:location) do
          address.locations.create!(name: "home")
        end

        before do
          Person.collection.find({ "_id" => person.id }).
            update_one({ "$set" => { "addresses.0.locations.0.name" => "work" }})
        end

        let!(:reloaded) do
          location.reload
        end

        it "reloads the embedded document attributes" do
          expect(reloaded.name).to eq("work")
        end

        it "reloads the reference on the parent" do
          expect(address.locations.first).to eq(reloaded)
        end

        it "reloads the reference on the root" do
          expect(person.addresses.first.locations.first).to eq(reloaded)
        end
      end
    end

    context "when embedded documents change" do

      let(:person) do
        Person.create!
      end

      let!(:address) do
        person.addresses.create!(number: 27, street: "Maiden Lane")
      end

      before do
        Person.collection.find({ "_id" => person.id }).
          update_one({ "$set" => { "addresses" => [] }})
        person.reload
      end

      it "reloads the association" do
        expect(person.addresses).to be_empty
      end
    end

    context "when embedded documents are unasssigned and reassigned" do

      context "when broken_updates feature flag is not set" do
        config_override :broken_updates, false

        let(:palette) do
          Palette.new
        end

        let(:canvas) do
          Canvas.create!
        end

        before do
          canvas.palette = palette
          canvas.palette = nil
          canvas.palette = palette
          canvas.save!
          canvas.reload
        end

        it "reloads the embedded document correctly" do
          expect(canvas.palette).to eq(palette)
        end
      end

      context "when broken_updates feature flag is set" do
        config_override :broken_updates, true

        let(:palette) do
          Palette.new
        end

        let(:canvas) do
          Canvas.create!
        end

        before do
          canvas.palette = palette
          canvas.palette = nil
          canvas.palette = palette
          canvas.save!
          canvas.reload
        end

        it "does not reload the embedded document correctly" do
          expect(canvas.palette).to be_nil
        end
      end
    end

    context "when embeds_many documents are cleared and reassigned" do

      context "when broken_updates feature flag is not set" do
        config_override :broken_updates, false

        let(:contractor) do
          Contractor.new(name: 'contractor')
        end

        let(:building) do
          Building.create!
        end

        it "persists an embedded document correctly the second time" do
          building.contractors << contractor
          expect(building.contractors).to eq([contractor])

          building.contractors.clear
          expect(building.contractors).to eq([])

          building.contractors << contractor
          building.reload
          expect(building.contractors).to eq([contractor])
        end
      end

      context "when broken_updates feature flag is set" do
        config_override :broken_updates, true

        let(:contractor) do
          Contractor.new(name: 'contractor')
        end

        let(:building) do
          Building.create!
        end

        it "doesn't persist the embedded document correctly the second time" do
          building.contractors << contractor
          expect(building.contractors).to eq([contractor])

          building.contractors.clear
          expect(building.contractors).to eq([])

          building.contractors << contractor
          building.reload
          expect(building.contractors).to eq([])
        end
      end
    end

    context "when embedded document is nil" do

      let(:palette) do
        Palette.new
      end

      let(:canvas) do
        Canvas.create!(palette: palette)
      end

      before do
        canvas.palette = nil
      end

      let(:reload) do
        palette.reload
      end

      it "raises a document not found error" do
        expect do
          reload
        end.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Palette with id\(s\)/)
      end
    end

    context "with relational associations" do

      let(:person) do
        Person.create!
      end

      context "for a has_one" do

        let!(:game) do
          person.create_game(score: 50)
        end

        before do
          Game.collection.find({ "_id" => game.id }).
            update_one({ "$set" => { "score" => 75 }})
          person.reload
        end

        it "reloads the association" do
          expect(person.game.score).to eq(75)
        end
      end

      context "for a belongs_to" do

        context "when the relation type does not change" do

          let!(:game) do
            person.create_game(score: 50)
          end

          before do
            Person.collection.find({ "_id" => person.id }).
              update_one({ "$set" => { "title" => "Mam" }})
            game.reload
          end

          it "reloads the association" do
            expect(game.person.title).to eq("Mam")
          end
        end
      end
    end

    context "when overriding #id alias" do

      let!(:object) do
        IdKey.create!(key: 'foo')
      end

      let!(:from_db) do
        IdKey.find(object._id).tap do |object|
          object.key = 'bar'
          object.save!
        end
      end

      it "reloads the object attributes from the db" do
        object.reload
        expect(object.key).to eq('bar')
      end

      it "reload should return self" do
        expect(object.reload).to eq(from_db)
      end
    end

    context 'when the document is readonly' do

      before do
        Person.create!
      end

      context "when legacy_readonly is on" do
        config_override :legacy_readonly, true

        let(:reloaded) do
          Person.only(:name).first.reload
        end

        it 'resets the readonly state after reloading' do
          expect(reloaded.readonly?).to be(false)
        end
      end

      context "when legacy_readonly is off" do
        config_override :legacy_readonly, false

        let(:reloaded) do
          Person.only(:name).first.tap do |doc|
            doc.readonly!
            expect(doc.readonly?).to be true
            doc.reload
          end
        end

        it 'does not reset the readonly state after reloading' do
          expect(reloaded.readonly?).to be(true)
        end
      end
    end

    context 'on sharded cluster' do
      require_topology :sharded

      before(:all) do
        CONFIG[:clients][:other] = CONFIG[:clients][:default].dup
        CONFIG[:clients][:other][:database] = 'other'
        Mongoid::Clients.clients.values.each(&:close)
        Mongoid::Config.send(:clients=, CONFIG[:clients])
        Mongoid::Clients.with_name(:other).subscribe(Mongo::Monitoring::COMMAND, EventSubscriber.new)
      end

      let(:subscriber) do
        client = Mongoid::Clients.with_name(:other)
        monitoring = client.send(:monitoring)
        subscriber = monitoring.subscribers['Command'].find do |s|
          s.is_a?(EventSubscriber)
        end
      end

      let(:find_events) do
        find_events = subscriber.started_events.select { |event| event.command_name.to_s == 'find' }
      end

      before do
        subscriber.clear_events!
      end

      context 'without embedded document' do
        let(:profile) do
          Profile.with(client: :other) do |klass|
            klass.create!
          end
        end

        before do
          Profile.with(client: :other) do
            profile.reload
          end
        end

        it 'uses the shard key to reload the document' do
          expect(find_events.length). to eq(1)

          event = find_events.first
          expect(event.command['filter'].keys).to include('name')
        end
      end


      context 'with embedded document' do
        let(:profile_image) do
          Profile.with(client: :other) do |klass|
            profile = klass.create!
            ProfileImage.create!(profile: profile)
          end
        end

        before do
          Profile.with(client: :other) do
            profile_image.reload
          end
        end

        it 'uses the shard key to reload the embedded document' do
          expect(find_events.length). to eq(1)

          event = find_events.first
          expect(event.command['filter'].keys).to include('name')
        end
      end
    end

    context 'when raise_not_found_error is false' do
      config_override :raise_not_found_error, false

      let!(:band) { Band.create!(name: 'Sun Project') }

      context 'when document exists in the database' do
        before do
          band.name = 'test'
        end

        it 'reloads the document' do
          band.name.should == 'test'

          band.reload

          band.name.should == 'Sun Project'
        end
      end

      context 'when document does not exist in the database' do
        before do
          band.name = 'test'

          band.destroy
        end

        it 'creates a new document with default values' do
          original_id = band.id
          band.name.should == 'test'

          band.reload

          band.name.should be nil
          band.id.should_not be nil
          # _id changes
          band.id.should_not == original_id
        end
      end
    end

    context 'when document has referenced associations' do
      let!(:church) do
        Church.create!(name: 'Test', acolytes: [Acolyte.new(name: 'Borg')])
      end

      before do
        church.acolytes.first.name = 'test'
      end

      it 'resets the associations' do
        church.acolytes.first.name.should == 'test'

        church.reload

        church.acolytes._loaded?.should be false

        church.acolytes.first.name.should == 'Borg'
      end
    end

    context 'when document has previous changes' do
      context 'when document was updated' do
        let(:person) do
          Person.create!(title: 'Sir')
        end

        before do
          person.title = 'Madam'
          person.save!
          person.reload
        end

        it "resets previous changes" do
          expect(person.title_previously_was).to be_nil
          expect(person).not_to be_previously_persisted
        end
      end

      context 'when document was created' do
        let(:person) do
          Person.create!(title: 'Sir')
        end

        before do
          person.reload
        end

        it "resets previous changes" do
          expect(person).not_to be_previously_new_record
        end
      end
    end
  end
end
