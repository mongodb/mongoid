# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria do

  describe "#==" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    context "when the other is a criteria" do

      context "when the criteria are the same" do

        let(:other) do
          Band.where(name: "Depeche Mode")
        end

        it "returns true" do
          expect(criteria).to eq(other)
        end
      end

      context "when the criteria differ" do

        let(:other) do
          Band.where(name: "Tool")
        end

        it "returns false" do
          expect(criteria).to_not eq(other)
        end
      end
    end

    context "when the other is an enumerable" do

      context "when the entries are the same" do

        let!(:band) do
          Band.create!(name: "Depeche Mode")
        end

        let(:other) do
          [ band ]
        end

        it "returns true" do
          expect(criteria).to eq(other)
        end
      end

      context "when the entries are not the same" do

        let!(:band) do
          Band.create!(name: "Depeche Mode")
        end

        let!(:other_band) do
          Band.create!(name: "Tool")
        end

        let(:other) do
          [ other_band ]
        end

        it "returns false" do
          expect(criteria).to_not eq(other)
        end
      end
    end

    context "when the other is neither a criteria or enumerable" do

      it "returns false" do
        expect(criteria).to_not eq("test")
      end
    end
  end

  describe "#===" do

    context "when the other is a criteria" do

      let(:other) do
        Band.where(name: "Depeche Mode")
      end

      it "returns true" do
        expect(described_class === other).to be true
      end
    end

    context "when the other is not a criteria" do

      it "returns false" do
        expect(described_class === []).to be false
      end
    end
  end

  describe "#asc" do

    let(:person) do
      Person.create!
    end

    context "when the documents are embedded" do

      let!(:hobrecht) do
        person.addresses.create!(street: "hobrecht", name: "hobrecht")
      end

      let!(:friedel) do
        person.addresses.create!(street: "friedel", name: "friedel")
      end

      let!(:pfluger) do
        person.addresses.create!(street: "pfluger", name: "pfluger")
      end

      let(:criteria) do
        person.addresses.asc(:name)
      end

      it "returns the sorted documents" do
        expect(criteria).to eq([ friedel, hobrecht, pfluger ])
      end
    end
  end

  describe "#batch_size" do

    let(:person) do
      Person.create!
    end

    let(:criteria) do
      Person.batch_size(1000)
    end

    it "adds the batch size option" do
      expect(criteria.options[:batch_size]).to eq(1000)
    end

    it "returns the correct documents" do
      expect(criteria).to eq([ person ])
    end
  end

  describe "#read" do

    let(:person) do
      Person.create!
    end

    let(:criteria) do
      Person.read(mode: :secondary)
    end

    it "adds the read option" do
      expect(criteria.options[:read]).to eq(mode: :secondary)
    end
  end

  describe "#aggregates" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create!(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      let(:aggregates) do
        criteria.aggregates(:likes)
      end

      it "returns an avg" do
        expect(aggregates["avg"]).to eq(750)
      end

      it "returns a count" do
        expect(aggregates["count"]).to eq(2)
      end

      it "returns a max" do
        expect(aggregates["max"]).to eq(1000)
      end

      it "returns a min" do
        expect(aggregates["min"]).to eq(500)
      end

      it "returns a sum" do
        expect(aggregates["sum"]).to eq(1500)
      end
    end
  end

  describe "#avg" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create!(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      let(:avg) do
        criteria.avg(:likes)
      end

      it "returns the avg of the provided field" do
        expect(avg).to eq(750)
      end
    end
  end

  [ :all, :all_in ].each do |method|

    describe "\##{method}" do

      let!(:match) do
        Band.create!(genres: [ "electro", "dub" ])
      end

      let!(:non_match) do
        Band.create!(genres: [ "house" ])
      end

      let(:criteria) do
        Band.send(method, genres: [ "electro", "dub" ])
      end

      it "returns the matching documents" do
        expect(criteria).to eq([ match ])
      end
    end
  end

  [ :and, :all_of ].each do |method|

    describe "\##{method}" do

      let!(:match) do
        Band.create!(name: "Depeche Mode", genres: [ "electro" ])
      end

      let!(:non_match) do
        Band.create!(genres: [ "house" ])
      end

      let(:criteria) do
        Band.send(method, { genres: "electro" }, { name: "Depeche Mode" })
      end

      it "returns the matching documents" do
        expect(criteria).to eq([ match ])
      end
    end
  end

  describe "#as_json" do

    let!(:band) do
      Band.create!(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    # as_json changed in rails 6 to call as_json on serializable_hash.
    # https://github.com/rails/rails/commit/2e5cb980a448e7f4ab00df6e9ad4c1cc456616aa

    context 'rails < 6' do
      max_rails_version '5.2'

      it "returns the criteria as a json hash" do
        expect(criteria.as_json).to eq([ band.serializable_hash ])
      end
    end

    context 'rails >= 6' do
      min_rails_version '6.0'

      it "returns the criteria as a json hash" do
        expect(criteria.as_json).to eq([ band.serializable_hash.as_json ])
      end
    end
  end

  describe "#between" do

    let!(:match) do
      Band.create!(member_count: 3)
    end

    let!(:non_match) do
      Band.create!(member_count: 10)
    end

    let(:criteria) do
      Band.between(member_count: 1..5)
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  [ :build, :new ].each do |method|

    describe "##{method}" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      context "when provided valid attributes" do

        let(:band) do
          criteria.send(method, genres: [ "electro" ])
        end

        it "returns the new document" do
          expect(band).to be_new_record
        end

        it "sets the criteria attributes" do
          expect(band.name).to eq("Depeche Mode")
        end

        it "sets the attributes passed to build" do
          expect(band.genres).to eq([ "electro" ])
        end
      end

      context "when provided a block" do
        context "when provided valid attributes" do
          let(:band) do
            criteria.send(method) do |c|
              c.genres = [ "electro" ]
            end
          end

          it "returns the new document" do
            expect(band).to be_new_record
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
  end

  describe "#cache" do

    let!(:person) do
      Person.create!
    end

    context "when the query cache is enabled" do
      query_cache_enabled

      let(:criteria) do
        Person.all
      end

      before do
        criteria.each {}
      end

      it "does not hit the database after first iteration" do
        expect_no_queries do
          criteria.each do |doc|
            expect(doc).to eq(person)
          end
        end
      end
    end

    context "when the criteria is eager loading" do
      query_cache_enabled

      let(:criteria) do
        Person.includes(:posts)
      end

      before do
        criteria.each {}
      end

      it "does not hit the database after first iteration" do
        expect_no_queries do
          criteria.each do |doc|
            expect(doc).to eq(person)
          end
        end
      end
    end
  end

  [ :clone, :dup ].each do |method|

    describe "\##{method}" do

      let(:band) do
        Band.new
      end

      let(:criteria) do
        Band.where(name: "Depeche Mode").asc(:name).includes(:records).read(mode: :secondary)
      end

      before do
        criteria.documents = [ band ]
        criteria.context
      end

      let(:clone) do
        criteria.send(method)
      end

      it "contains an equal selector" do
        expect(clone.selector).to eq({ "name" => "Depeche Mode" })
      end

      it "clones the selector" do
        expect(clone.selector).to_not equal(criteria.selector)
      end

      it "contains equal options" do
        expect(clone.options).to eq({ sort: { "name" => 1 }, read: { mode: :secondary } })
      end

      it "clones the options" do
        expect(clone.options).to_not equal(criteria.options)
      end

      it "contains equal inclusions" do
        expect(clone.inclusions).to eq([ Band.relations["records"] ])
      end

      it "clones the inclusions" do
        expect(clone.inclusions).to_not equal(criteria.inclusions)
      end

      it "contains equal documents" do
        expect(clone.documents).to eq([ band ])
      end

      it "clones the documents" do
        expect(clone.documents).to_not equal(criteria.documents)
      end

      it "contains equal scoping options" do
        expect(clone.scoping_options).to eq([ nil, nil ])
      end

      it "clones the scoping options" do
        expect(clone.scoping_options).to_not equal(criteria.scoping_options)
      end

      it "sets the context to nil" do
        expect(clone.instance_variable_get(:@context)).to be_nil
      end

      it 'does not convert the option keys to string from symbols' do
        expect(clone.options[:read][:mode]).to eq(:secondary)
      end
    end
  end

  describe "#context" do

    context "when the model is embedded" do

      let(:criteria) do
        described_class.new(Record) do |criteria|
          criteria.embedded = true
        end
      end

      it "returns the embedded context" do
        expect(criteria.context).to be_a(Mongoid::Contextual::Memory)
      end
    end

    context "when the model is not embedded" do

      let(:criteria) do
        described_class.new(Band)
      end

      it "returns the mongo context" do
        expect(criteria.context).to be_a(Mongoid::Contextual::Mongo)
      end
    end
  end

  describe "#delete" do

    let(:depeche) do
      Band.create!(name: "Depeche Mode")
    end

    let(:tool) do
      Band.create!(name: "Tool")
    end

    context "when no selector is provided" do

      before do
        Band.all.delete
      end

      it "deletes all the documents from the database" do
        expect(Band.count).to eq(0)
      end
    end
  end

  describe "#documents" do

    let(:band) do
      Band.new
    end

    let(:criteria) do
      described_class.new(Band) do |criteria|
        criteria.documents = [ band ]
      end
    end

    it "returns the documents" do
      expect(criteria.documents).to eq([ band ])
    end
  end

  describe "#documents=" do

    let(:band) do
      Band.new
    end

    let(:criteria) do
      described_class.new(Band)
    end

    before do
      criteria.documents = [ band ]
    end

    it "sets the documents" do
      expect(criteria.documents).to eq([ band ])
    end
  end

  describe "#each" do

    let!(:band) do
      Band.create!(name: "Depeche Mode")
    end

    context "when provided a block" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      it "iterates over the matching documents" do
        criteria.each do |doc|
          expect(doc).to eq(band)
        end
      end
    end
  end

  describe "#elem_match" do

    let!(:match) do
      Band.create!(name: "Depeche Mode").tap do |band|
        r = band.records
        r.create!(name: "101")
      end
    end

    let!(:non_match) do
      Band.create!(genres: [ "house" ])
    end

    let(:criteria) do
      Band.elem_match(records: { name: "101" })
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#embedded?" do

    let(:person) do
      Person.new
    end

    context "when the criteria is embedded" do

      let(:criteria) do
        person.addresses.where(street: "hobrecht")
      end

      it "returns true" do
        expect(criteria).to be_embedded
      end
    end

    context "when the criteria is not embedded" do

      let(:criteria) do
        Person.where(active: true)
      end

      it "returns false" do
        expect(criteria).to_not be_embedded
      end
    end
  end

  describe "#empty?" do

    context "when matching documents exist" do

      let!(:match) do
        Band.create!(name: "Depeche Mode")
      end

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      it "returns false" do
        expect(criteria).to_not be_empty
      end
    end

    context "when no matching documents exist" do

      let!(:nonmatch) do
        Band.create!(name: "New Order")
      end

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      it "returns true" do
        expect(criteria).to be_empty
      end
    end
  end

  describe "#exists" do

    let!(:match) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:non_match) do
      Band.create!
    end

    let(:criteria) do
      Band.exists(name: true)
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#exists?" do

    context "when matching documents exist" do

      let!(:match) do
        Band.create!(name: "Depeche Mode")
      end

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      it "returns true" do
        expect(criteria.exists?).to be true
      end
    end

    context "when no matching documents exist" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      it "returns false" do
        expect(criteria.exists?).to be false
      end
    end
  end

  describe "#explain" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "returns the criteria explain path" do
      expect(criteria.explain).to_not be_empty
    end
  end

  describe "#extract_id" do

    let(:id) do
      BSON::ObjectId.new
    end

    context "when an id exists" do

      let(:criteria) do
        described_class.new(Band) do |criteria|
          criteria.selector[:id] = id
        end
      end

      it "returns the id" do
        expect(criteria.extract_id).to eq(id)
      end
    end

    context "when an _id exists" do

      let(:criteria) do
        described_class.new(Band) do |criteria|
          criteria.selector[:_id] = id
        end
      end

      it "returns the _id" do
        expect(criteria.extract_id).to eq(id)
      end
    end
  end

  describe "#field_list" do

    context "when using the default discriminator key" do
      let(:criteria) do
        Doctor.only(:_id)
      end

      it "returns the fields with required _id minus type" do
        expect(criteria.field_list).to eq([ "_id" ])
      end
    end

    context "when using a custom discriminator key" do
      before do
        Person.discriminator_key = "dkey"
      end

      after do
        Person.discriminator_key = nil
      end

      let(:criteria) do
        Doctor.only(:_id, :_type)
      end

      it "returns the fields with type without dkey" do
        expect(criteria.field_list).to eq([ "_id", "_type" ])
      end
    end
  end

  describe "#find" do
    let!(:depeche) do
      Band.create!(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    context "when given a block" do
      it "behaves as Enumerable" do
        result = criteria.find { |c| c.name == "Depeche Mode" }
        expect(result).to eq(depeche)
      end
    end

    context "when given a Proc and a block" do
      it "behaves as Enumerable" do
        result = criteria.find(-> {"default"}) { |c| c.name == "Not Depeche Mode" }
        expect(result).to eq("default")
      end
    end

    context "when given a Proc without a block" do
      it "raises an error" do
        lambda do
          criteria.find(-> {"default"})
        # Proc is not serializable to a BSON type
        end.should raise_error(BSON::Error::UnserializableClass)
      end
    end

    context "when given an id" do
      it "behaves as Findable" do
        result = criteria.find(depeche.id)
        expect(result).to eq(depeche)
      end
    end
  end

  describe "#find_one_and_update" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:tool) do
      Band.create!(name: "Tool")
    end

    context "when the selector matches" do

      context "when the identity map is enabled" do

        context "when returning the updated document" do

          let(:criteria) do
            Band.where(name: "Depeche Mode")
          end

          let(:result) do
            criteria.find_one_and_update({ "$inc" => { likes: 1 }}, return_document: :after)
          end

          it "returns the first matching document" do
            expect(result).to eq(depeche)
          end
        end

        context "when not returning the updated document" do

          let(:criteria) do
            Band.where(name: "Depeche Mode")
          end

          let!(:result) do
            criteria.find_one_and_update("$inc" => { likes: 1 })
          end

          before do
            depeche.reload
          end

          it "returns the first matching document" do
            expect(result).to eq(depeche)
          end
        end
      end

      context "when not providing options" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let!(:result) do
          criteria.find_one_and_update("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "updates the document in the database" do
          expect(depeche.reload.likes).to eq(1)
        end
      end

      context "when sorting" do

        let(:criteria) do
          Band.desc(:name)
        end

        let!(:result) do
          criteria.find_one_and_update("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          expect(result).to eq(tool)
        end

        it "updates the document in the database" do
          expect(tool.reload.likes).to eq(1)
        end
      end

      context "when limiting fields" do

        let(:criteria) do
          Band.only(:_id)
        end

        let!(:result) do
          criteria.find_one_and_update("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "limits the returned fields" do
          expect(result.name).to be_nil
        end

        it "updates the document in the database" do
          expect(depeche.reload.likes).to eq(1)
        end
      end

      context "when returning new" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let!(:result) do
          criteria.find_one_and_update({ "$inc" => { likes: 1 }}, return_document: :after)
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "returns the updated document" do
          expect(result.likes).to eq(1)
        end
      end

      context "when removing" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let!(:result) do
          criteria.find_one_and_delete
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "deletes the document from the database" do
          expect {
            depeche.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Band with id\(s\)/)
        end
      end
    end

    context "when the selector does not match" do

      let(:criteria) do
        Band.where(name: "Placebo")
      end

      let(:result) do
        criteria.find_one_and_update("$inc" => { likes: 1 })
      end

      context "without upsert" do

        let(:result) do
          criteria.find_one_and_update("$inc" => { likes: 1 })
        end

        it "returns nil" do
          expect(result).to be_nil
        end
      end
    end
  end

  describe "#freeze" do

    let(:criteria) do
      Band.all
    end

    before do
      criteria.freeze
    end

    it "freezes the criteria" do
      expect(criteria).to be_frozen
    end

    it "initializes inclusions" do
      expect(criteria.inclusions).to be_empty
    end

    it "initializes the context" do
      expect(criteria.context).to_not be_nil
    end
  end

  describe "#geo_near" do
    max_server_version '4.0'

    before do
      Bar.create_indexes
    end

    let!(:match) do
      Bar.create!(location: [ 52.30, 13.25 ])
    end

    let(:criteria) do
      Bar.geo_near([ 52, 13 ]).max_distance(10).spherical
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#eq" do

    let!(:match) do
      Band.create(member_count: 5)
    end

    let!(:non_match) do
      Band.create(member_count: 1)
    end

    let(:criteria) do
      Band.eq(member_count: 5)
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#gt" do

    let!(:match) do
      Band.create!(member_count: 5)
    end

    let!(:non_match) do
      Band.create!(member_count: 1)
    end

    let(:criteria) do
      Band.gt(member_count: 4)
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#gte" do

    let!(:match) do
      Band.create!(member_count: 5)
    end

    let!(:non_match) do
      Band.create!(member_count: 1)
    end

    let(:criteria) do
      Band.gte(member_count: 5)
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  [ :in, :any_in ].each do |method|

    describe "\##{method}" do

      context "when querying on a normal field" do

        let!(:match) do
          Band.create!(genres: [ "electro", "dub" ])
        end

        let!(:non_match) do
          Band.create!(genres: [ "house" ])
        end

        let(:criteria) do
          Band.send(method, genres: [ "dub" ])
        end

        it "returns the matching documents" do
          expect(criteria).to eq([ match ])
        end
      end

      context "when querying on a foreign key" do

        let(:id) do
          BSON::ObjectId.new
        end

        let!(:match_one) do
          Person.create!(preference_ids: [ id ])
        end

        context "when providing valid ids" do

          let(:criteria) do
            Person.send(method, preference_ids: [ id ])
          end

          it "returns the matching documents" do
            expect(criteria).to eq([ match_one ])
          end
        end

        context "when providing empty strings" do

          let(:criteria) do
            Person.send(method, preference_ids: [ id, "" ])
          end

          it "returns the matching documents" do
            expect(criteria).to eq([ match_one ])
          end
        end

        context "when providing nils" do

          context "when the relation is a many to many" do

            let(:criteria) do
              Person.send(method, preference_ids: [ id, nil ])
            end

            it "returns the matching documents" do
              expect(criteria).to eq([ match_one ])
            end
          end

          context "when the relation is a one to one" do

            let!(:game) do
              Game.create!
            end

            let(:criteria) do
              Game.send(method, person_id: [ nil ])
            end

            it "returns the matching documents" do
              expect(criteria).to eq([ game ])
            end
          end
        end
      end
    end
  end

  describe "#initialize" do

    let(:criteria) do
      described_class.new(Band)
    end

    it "sets the class" do
      expect(criteria.klass).to eq(Band)
    end

    it "sets the aliased fields" do
      expect(criteria.aliased_fields).to eq(Band.aliased_fields)
    end

    it "sets the serializers" do
      expect(criteria.serializers).to eq(Band.fields)
    end
  end

  describe "#lt" do

    let!(:match) do
      Band.create!(member_count: 1)
    end

    let!(:non_match) do
      Band.create!(member_count: 5)
    end

    let(:criteria) do
      Band.lt(member_count: 4)
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#lte" do

    let!(:match) do
      Band.create!(member_count: 4)
    end

    let!(:non_match) do
      Band.create!(member_count: 5)
    end

    let(:criteria) do
      Band.lte(member_count: 4)
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#map_reduce" do

    let(:map) do
      %Q{
      function() {
        emit(this.name, { likes: this.likes });
      }}
    end

    let(:reduce) do
      %Q{
      function(key, values) {
        var result = { likes: 0 };
        values.forEach(function(value) {
          result.likes += value.likes;
        });
        return result;
      }}
    end

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode", likes: 200)
    end

    let!(:tool) do
      Band.create!(name: "Tool", likes: 100)
    end

    context "when no timeout options are provided" do

      let(:map_reduce) do
        Band.limit(2).map_reduce(map, reduce).out(inline: 1)
      end

      it "returns the map/reduce results" do
        expect(map_reduce.sort_by { |doc| doc['_id'] }).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }},
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        ])
      end
    end
  end

  describe "#max" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create!(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      context "when provided a symbol" do

        let(:max) do
          criteria.max(:likes)
        end

        it "returns the max of the provided field" do
          expect(max).to eq(1000)
        end
      end

      context "when provided a block" do

        let(:max) do
          criteria.max do |a, b|
            a.likes <=> b.likes
          end
        end

        it "returns the document with the max value for the field" do
          expect(max).to eq(depeche)
        end
      end
    end
  end

  describe "#max_distance" do

    before do
      Bar.create_indexes
    end

    let!(:match) do
      Bar.create!(location: [ 52.30, 13.25 ])
    end

    let!(:non_match) do
      Bar.create!(location: [ 19.26, 99.70 ])
    end

    let(:criteria) do
      Bar.near(location: [ 52, 13 ]).max_distance(location: 5)
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#merge" do

    let(:band) do
      Band.new
    end

    let(:criteria) do
      Band.scoped.where(name: "Depeche Mode").asc(:name)
    end

    context "when merging with another criteria" do

      let(:mergeable) do
        Band.includes(:records).tap do |crit|
          crit.documents = [ band ]
        end
      end

      let(:association) do
        Band.relations["records"]
      end

      let(:merged) do
        criteria.merge(mergeable)
      end

      it "merges the selector" do
        expect(merged.selector).to eq({ "name" => "Depeche Mode" })
      end

      it "merges the options" do
        expect(merged.options).to eq({ sort: { "name" => 1 }})
      end

      it "merges the documents" do
        expect(merged.documents).to eq([ band ])
      end

      it "merges the scoping options" do
        expect(merged.scoping_options).to eq([ nil, nil ])
      end

      it "merges the inclusions" do
        expect(merged.inclusions).to eq([ association ])
      end

      it "returns a new criteria" do
        expect(merged).to_not equal(criteria)
      end
    end

    context "when merging with a hash" do

      let(:mergeable) do
        { klass: Band, includes: [ :records ] }
      end

      let(:association) do
        Band.relations["records"]
      end

      let(:merged) do
        criteria.merge(mergeable)
      end

      it "merges the selector" do
        expect(merged.selector).to eq({ "name" => "Depeche Mode" })
      end

      it "merges the options" do
        expect(merged.options).to eq({ sort: { "name" => 1 }})
      end

      it "merges the scoping options" do
        expect(merged.scoping_options).to eq([ nil, nil ])
      end

      it "merges the inclusions" do
        expect(merged.inclusions).to eq([ association ])
      end

      it "returns a new criteria" do
        expect(merged).to_not equal(criteria)
      end
    end
  end

  describe "#merge!" do

    let(:band) do
      Band.new
    end

    let(:criteria) do
      Band.scoped.where(name: "Depeche Mode").asc(:name)
    end

    let(:mergeable) do
      Band.includes(:records).tap do |crit|
        crit.documents = [ band ]
      end
    end

    let(:association) do
      Band.relations["records"]
    end

    let(:merged) do
      criteria.merge!(mergeable)
    end

    it "merges the selector" do
      expect(merged.selector).to eq({ "name" => "Depeche Mode" })
    end

    it "merges the options" do
      expect(merged.options).to eq({ sort: { "name" => 1 }})
    end

    it "merges the documents" do
      expect(merged.documents).to eq([ band ])
    end

    it "merges the scoping options" do
      expect(merged.scoping_options).to eq([ nil, nil ])
    end

    it "merges the inclusions" do
      expect(merged.inclusions).to eq([ association ])
    end

    it "returns the same criteria" do
      expect(merged).to equal(criteria)
    end
  end

  describe "#min" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create!(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      context "when provided a symbol" do

        let(:min) do
          criteria.min(:likes)
        end

        it "returns the min of the provided field" do
          expect(min).to eq(500)
        end
      end

      context "when provided a block" do

        let(:min) do
          criteria.min do |a, b|
            a.likes <=> b.likes
          end
        end

        it "returns the document with the min value for the field" do
          expect(min).to eq(tool)
        end
      end
    end
  end

  describe "#mod" do

    let!(:match) do
      Band.create!(member_count: 5)
    end

    let!(:non_match) do
      Band.create!(member_count: 2)
    end

    let(:criteria) do
      Band.mod(member_count: [ 4, 1 ])
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#ne" do

    let!(:match) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:non_match) do
      Band.create!(name: "Tool")
    end

    let(:criteria) do
      Band.ne(name: "Tool")
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#near" do

    before do
      Bar.create_indexes
    end

    let!(:match) do
      Bar.create!(location: [ 52.30, 13.25 ])
    end

    let(:criteria) do
      Bar.near(location: [ 52, 13 ])
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#near_sphere" do

    before do
      Bar.create_indexes
    end

    let!(:match) do
      Bar.create!(location: [ 52.30, 13.25 ])
    end

    let(:criteria) do
      Bar.near_sphere(location: [ 52, 13 ])
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#nin" do

    let!(:match) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:non_match) do
      Band.create!(name: "Tool")
    end

    let(:criteria) do
      Band.nin(name: [ "Tool" ])
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#nor" do

    let!(:match) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:non_match) do
      Band.create!(name: "Tool")
    end

    let(:criteria) do
      Band.nor({ name: "Tool" }, { name: "New Order" })
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  [ :or, :any_of ].each do |method|

    describe "\##{method}" do

      let!(:match) do
        Band.create!(name: "Depeche Mode")
      end

      let!(:non_match) do
        Band.create!(name: "Tool")
      end

      context "when sending a normal $or criterion" do

        let(:criteria) do
          Band.send(method, { name: "Depeche Mode" }, { name: "New Order" })
        end

        it "returns the matching documents" do
          expect(criteria).to eq([ match ])
        end
      end

      context "when matching against an id or other parameter" do

        let(:criteria) do
          Band.send(method, { id: match.id }, { name: "New Order" })
        end

        it "returns the matching documents" do
          expect(criteria).to eq([ match ])
        end
      end
    end
  end

  describe "#pluck" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode", likes: 3)
    end

    let!(:tool) do
      Band.create!(name: "Tool", likes: 3)
    end

    let!(:photek) do
      Band.create!(name: "Photek", likes: 1)
    end

    let(:maniacs) do
      Band.create!(name: "10,000 Maniacs", likes: 1, sales: "1E2")
    end

    context "when the field is aliased" do

      let!(:expensive) do
        Product.create!(price: 100000)
      end

      let!(:cheap) do
        Product.create!(price: 1)
      end

      context "when using alias_attribute" do

        let(:plucked) do
          Product.pluck(:price)
        end

        with_config_values :legacy_pluck_distinct, true, false do
          it "uses the aliases" do
            expect(plucked).to eq([ 100000, 1 ])
          end
        end
      end
    end

    context "when the criteria matches" do

      context "when there are no duplicate values" do

        let(:criteria) do
          Band.where(:name.exists => true)
        end

        let!(:plucked) do
          criteria.pluck(:name)
        end

        with_config_values :legacy_pluck_distinct, true, false do
          it "returns the values" do
            expect(plucked).to contain_exactly("Depeche Mode", "Tool", "Photek")
          end
        end

        context "when subsequently executing the criteria without a pluck" do

          with_config_values :legacy_pluck_distinct, true, false do
            it "does not limit the fields" do
              expect(criteria.first.likes).to eq(3)
            end
          end
        end

        context 'when the field is a subdocument' do

          let(:criteria) do
            Band.where(name: 'FKA Twigs')
          end

          context 'when a top-level field and a subdocument field are plucked' do
            before do
              Band.create!(name: 'FKA Twigs')
              Band.create!(name: 'FKA Twigs', records: [ Record.new(name: 'LP1') ])
            end

            let(:embedded_pluck) do
              criteria.pluck(:name, 'records.name')
            end

            context "when legacy_pluck_distinct is set" do
              config_override :legacy_pluck_distinct, true
              let(:expected) do
                [
                  ["FKA Twigs", nil],
                  ['FKA Twigs', [{ "name" => "LP1" }]]
                ]
              end

              it 'returns the list of top-level field and subdocument values' do
                expect(embedded_pluck).to eq(expected)
              end
            end

            context "when legacy_pluck_distinct is not set" do
              config_override :legacy_pluck_distinct, false
              let(:expected) do
                [
                  ["FKA Twigs", nil],
                  ['FKA Twigs', ["LP1"]]
                ]
              end

              it 'returns the list of top-level field and subdocument values' do
                expect(embedded_pluck).to eq(expected)
              end
            end
          end

          context 'when only a subdocument field is plucked' do

            before do
              Band.create!(name: 'FKA Twigs')
              Band.create!(name: 'FKA Twigs', records: [ Record.new(name: 'LP1') ])
            end

            let(:embedded_pluck) do
              criteria.pluck('records.name')
            end

            context "when legacy_pluck_distinct is set" do
              config_override :legacy_pluck_distinct, true
              let(:expected) do
                [
                  nil,
                  [{ "name" => "LP1" }]
                ]
              end

              it 'returns the list of subdocument values' do
                expect(embedded_pluck).to eq(expected)
              end
            end

            context "when legacy_pluck_distinct is not set" do
              config_override :legacy_pluck_distinct, false
              let(:expected) do
                [
                  nil,
                  ["LP1"]
                ]
              end

              it 'returns the list of subdocument values' do
                expect(embedded_pluck).to eq(expected)
              end
            end
          end
        end
      end

      context "when plucking multi-fields" do

        let(:plucked) do
          Band.where(:name.exists => true).pluck(:name, :likes)
        end

        with_config_values :legacy_pluck_distinct, true, false do
          it "returns the values" do
            expect(plucked).to contain_exactly(["Depeche Mode", 3], ["Tool", 3], ["Photek", 1])
          end
        end
      end

      context "when there are duplicate values" do

        let(:plucked) do
          Band.where(:name.exists => true).pluck(:likes)
        end

        with_config_values :legacy_pluck_distinct, true, false do
          it "returns the duplicates" do
            expect(plucked).to contain_exactly(3, 3, 1)
          end
        end
      end
    end

    context "when the criteria does not match" do

      let(:plucked) do
        Band.where(name: "New Order").pluck(:_id)
      end

      with_config_values :legacy_pluck_distinct, true, false do
        it "returns an empty array" do
          expect(plucked).to be_empty
        end
      end
    end

    context "when plucking an aliased field" do

      let(:plucked) do
        Band.all.pluck(:id)
      end

      with_config_values :legacy_pluck_distinct, true, false do
        it "returns the field values" do
          expect(plucked).to eq([ depeche.id, tool.id, photek.id ])
        end
      end
    end

    context "when plucking existent and non-existent fields" do

      let(:plucked) do
        Band.all.pluck(:id, :fooz)
      end

      with_config_values :legacy_pluck_distinct, true, false do
        it "returns nil for the field that doesnt exist" do
          expect(plucked).to eq([[depeche.id, nil], [tool.id, nil], [photek.id, nil] ])
        end
      end
    end

    context "when plucking a field that doesnt exist" do

      context "when pluck one field" do

        let(:plucked) do
          Band.all.pluck(:foo)
        end

        with_config_values :legacy_pluck_distinct, true, false do
          it "returns an array with nil values" do
            expect(plucked).to eq([nil, nil, nil])
          end
        end
      end

      context "when pluck multiple fields" do

        let(:plucked) do
          Band.all.pluck(:foo, :bar)
        end

        with_config_values :legacy_pluck_distinct, true, false do
          it "returns an array of arrays with nil values" do
            expect(plucked).to eq([[nil, nil], [nil, nil], [nil, nil]])
          end
        end
      end
    end

    context 'when plucking a localized field' do
      with_default_i18n_configs

      before do
        I18n.locale = :en
        d = Dictionary.create!(description: 'english-text')
        I18n.locale = :de
        d.description = 'deutsch-text'
        d.save!
      end

      context 'when plucking the entire field' do
        let(:plucked) do
          Dictionary.all.pluck(:description)
        end

        let(:plucked_translations) do
          Dictionary.all.pluck(:description_translations)
        end

        let(:plucked_translations_both) do
          Dictionary.all.pluck(:description_translations, :description)
        end

        context "when legacy_pluck_distinct is set" do
          config_override :legacy_pluck_distinct, true

          it 'returns the non-demongoized translations' do
            expect(plucked.first).to eq({"de"=>"deutsch-text", "en"=>"english-text"})
          end

          it 'returns nil' do
            expect(plucked_translations.first).to eq(nil)
          end

          it 'returns nil for _translations' do
            expect(plucked_translations_both.first).to eq([nil, {"de"=>"deutsch-text", "en"=>"english-text"}])
          end
        end

        context "when legacy_pluck_distinct is not set" do
          config_override :legacy_pluck_distinct, false

          it 'returns the demongoized translations' do
            expect(plucked.first).to eq('deutsch-text')
          end

          it 'returns the full translations hash to _translations' do
            expect(plucked_translations.first).to eq({"de"=>"deutsch-text", "en"=>"english-text"})
          end

          it 'returns both' do
            expect(plucked_translations_both.first).to eq([{"de"=>"deutsch-text", "en"=>"english-text"}, "deutsch-text"])
          end
        end
      end

      context 'when plucking a specific locale' do

        let(:plucked) do
          Dictionary.all.pluck(:'description.de')
        end

        context "when legacy_pluck_distinct is set" do
          config_override :legacy_pluck_distinct, true

          it 'returns the specific translations' do
            expect(plucked.first).to eq({'de' => 'deutsch-text'})
          end
        end

        context "when legacy_pluck_distinct is not set" do
          config_override :legacy_pluck_distinct, false

          it 'returns the specific translations' do
            expect(plucked.first).to eq('deutsch-text')
          end
        end
      end

      context 'when plucking a specific locale from _translations field' do

        let(:plucked) do
          Dictionary.all.pluck(:'description_translations.de')
        end

        context "when legacy_pluck_distinct is set" do
          config_override :legacy_pluck_distinct, true

          it 'returns the specific translations' do
            expect(plucked.first).to eq(nil)
          end
        end

        context "when legacy_pluck_distinct is not set" do
          config_override :legacy_pluck_distinct, false

          it 'returns the specific translations' do
            expect(plucked.first).to eq('deutsch-text')
          end
        end
      end

      context 'when fallbacks are enabled with a locale list' do
        require_fallbacks

        before do
          I18n.fallbacks[:he] = [ :en ]
        end

        let(:plucked) do
          Dictionary.all.pluck(:description).first
        end

        context "when legacy_pluck_distinct is set" do
          config_override :legacy_pluck_distinct, true

          it "does not correctly use the fallback" do
            plucked.should == {"de"=>"deutsch-text", "en"=>"english-text"}
          end
        end

        context "when legacy_pluck_distinct is not set" do
          config_override :legacy_pluck_distinct, false

          it "correctly uses the fallback" do
            I18n.locale = :en
            d = Dictionary.create!(description: 'english-text')
            I18n.locale = :he
            plucked.should == "english-text"
          end
        end
      end

      context "when the localized field is embedded" do
        with_default_i18n_configs

        before do
          p = Passport.new
          I18n.locale = :en
          p.name = "Neil"
          I18n.locale = :he
          p.name = "Nissim"

          Person.create!(passport: p, employer_id: 12345)
        end

        let(:plucked) do
          Person.where(employer_id: 12345).pluck("pass.name").first
        end

        let(:plucked_translations) do
          Person.where(employer_id: 12345).pluck("pass.name_translations").first
        end

        let(:plucked_translations_field) do
          Person.where(employer_id: 12345).pluck("pass.name_translations.en").first
        end

        context "when legacy_pluck_distinct is set" do
          config_override :legacy_pluck_distinct, true

          it "returns the full hash embedded" do
            expect(plucked).to eq({ "name" => { "en" => "Neil", "he" => "Nissim" } })
          end

          it "returns the empty hash" do
            expect(plucked_translations).to eq({})
          end

          it "returns the empty hash" do
            expect(plucked_translations_field).to eq({})
          end
        end

        context "when legacy_pluck_distinct is not set" do
          config_override :legacy_pluck_distinct, false

          it "returns the translation for the current locale" do
            expect(plucked).to eq("Nissim")
          end

          it "returns the full _translation hash" do
            expect(plucked_translations).to eq({ "en" => "Neil", "he" => "Nissim" })
          end

          it "returns the translation for the requested locale" do
            expect(plucked_translations_field).to eq("Neil")
          end
        end
      end
    end

    context 'when plucking a field to be demongoized' do

      let(:plucked) do
        Band.where(name: maniacs.name).pluck(:sales)
      end

      context "when legacy_pluck_distinct is set" do
        config_override :legacy_pluck_distinct, true

        context 'when value is stored as string' do
          config_override :map_big_decimal_to_decimal128, false

          it "does not demongoize the field" do
            expect(plucked.first).to be_a(String)
            expect(plucked.first).to eq("1E2")
          end
        end

        context 'when value is stored as decimal128' do
          config_override :map_big_decimal_to_decimal128, true
          max_bson_version '4.99.99'

          it "does not demongoize the field" do
            expect(plucked.first).to be_a(BSON::Decimal128)
            expect(plucked.first).to eq(BSON::Decimal128.new("1E2"))
          end
        end
      end

      context "when legacy_pluck_distinct is not set" do
        config_override :legacy_pluck_distinct, false

        context 'when value is stored as string' do
          config_override :map_big_decimal_to_decimal128, false

          it "demongoizes the field" do
            expect(plucked.first).to be_a(BigDecimal)
            expect(plucked.first).to eq(BigDecimal("1E2"))
          end
        end

        context 'when value is stored as decimal128' do
          config_override :map_big_decimal_to_decimal128, true

          it "demongoizes the field" do
            expect(plucked.first).to be_a(BigDecimal)
            expect(plucked.first).to eq(BigDecimal("1E2"))
          end
        end
      end
    end

    context "when plucking an embedded field" do
      let(:label) { Label.new(sales: "1E2") }
      let!(:band) { Band.create!(label: label) }

      let(:plucked) { Band.where(_id: band.id).pluck("label.sales") }

      context "when legacy_pluck_distinct is set" do
        config_override :legacy_pluck_distinct, true
        config_override :map_big_decimal_to_decimal128, true
        max_bson_version '4.99.99'

        it "returns a hash with a non-demongoized field" do
          expect(plucked.first).to eq({ 'sales' => BSON::Decimal128.new('1E+2') })
        end
      end

      context "when legacy_pluck_distinct is not set" do
        config_override :legacy_pluck_distinct, false

        it "demongoizes the field" do
          expect(plucked).to eq([ BigDecimal("1E2") ])
        end
      end
    end

    context "when plucking an embeds_many field" do
      let(:label) { Label.new(sales: "1E2") }
      let!(:band) { Band.create!(labels: [label]) }

      let(:plucked) { Band.where(_id: band.id).pluck("labels.sales") }

      context "when legacy_pluck_distinct is set" do
        config_override :legacy_pluck_distinct, true
        config_override :map_big_decimal_to_decimal128, true
        max_bson_version '4.99.99'

        it "returns a hash with a non-demongoized field" do
          expect(plucked.first).to eq([{ 'sales' => BSON::Decimal128.new('1E+2') }])
        end
      end

      context "when legacy_pluck_distinct is not set" do
        config_override :legacy_pluck_distinct, false

        it "demongoizes the field" do
          expect(plucked.first).to eq([ BigDecimal("1E2") ])
        end
      end
    end

    context "when plucking a nonexistent embedded field" do
      let(:label) { Label.new(sales: "1E2") }
      let!(:band) { Band.create!(label: label) }

      let(:plucked) { Band.where(_id: band.id).pluck("label.qwerty") }

      context "when legacy_pluck_distinct is set" do
        config_override :legacy_pluck_distinct, true

        it "returns an empty hash" do
          expect(plucked.first).to eq({})
        end
      end

      context "when legacy_pluck_distinct is not set" do
        config_override :legacy_pluck_distinct, false

        it "returns nil" do
          expect(plucked.first).to eq(nil)
        end
      end
    end

    context "when tallying deeply nested arrays/embedded associations" do

      before do
        Person.create!(addresses: [ Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 2 } } ]))) ])
        Person.create!(addresses: [ Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 2 } } ]))) ])
        Person.create!(addresses: [ Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 3 } } ]))) ])
      end

      let(:plucked) do
        Person.pluck("addresses.code.deepest.array.y.z")
      end

      it "returns the correct hash" do
        expect(plucked).to eq([
          [ [ 1, 2 ] ], [ [ 1, 2 ] ], [ [ 1, 3 ] ]
        ])
      end
    end
  end

  describe "#pick" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode", likes: 3)
    end

    let!(:tool) do
      Band.create!(name: "Tool", likes: 3)
    end

    context "when picking a field" do

      let(:criteria) do
        Band.all
      end

      let(:picked) do
        criteria.pick(:name)
      end

      it "returns one element" do
        expect(picked).to eq("Depeche Mode")
      end
    end

    context "when picking multiple fields" do

      let(:criteria) do
        Band.all
      end

      let(:picked) do
        criteria.pick(:name, :likes)
      end

      it "returns an array" do
        expect(picked).to eq([ "Depeche Mode", 3 ])
      end
    end
  end

  describe "#respond_to?" do

    let(:criteria) do
      described_class.new(Person)
    end

    before do
      class Person
        def self.ages; self; end
      end
    end

    context "when asking about a model public class method" do

      it "returns true" do
        expect(criteria).to respond_to(:ages)
      end
    end

    context "when asking about a model private class method" do

      context "when including private methods" do

        it "returns true" do
          expect(criteria.respond_to?(:for_ids, true)).to be true
        end
      end
    end

    context "when asking about a model class public instance method" do

      it "returns true" do
        expect(criteria.respond_to?(:join)).to be true
      end
    end

    context "when asking about a model private instance method" do

      context "when not including private methods" do

        it "returns false" do
          expect(criteria).to_not respond_to(:initialize_copy)
        end
      end

      context "when including private methods" do

        it "returns true" do
          expect(criteria.respond_to?(:initialize_copy, true)).to be true
        end
      end
    end

    context "when asking about a criteria instance method" do

      it "returns true" do
        expect(criteria).to respond_to(:context)
      end
    end

    context "when asking about a private criteria instance method" do

      context "when not including private methods" do

        it "returns false" do
          expect(criteria).to_not respond_to(:puts)
        end
      end

      context "when including private methods" do

        it "returns true" do
          expect(criteria.respond_to?(:puts, true)).to be true
        end
      end
    end
  end

  describe "#sort" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode", likes: 1000)
    end

    let!(:tool) do
      Band.create!(name: "Tool", likes: 500)
    end

    let(:sorted) do
      Band.all.sort do |a, b|
        b.name <=> a.name
      end
    end

    it "sorts the results in memory" do
      expect(sorted).to eq([ tool, depeche ])
    end
  end

  describe "#sum" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create!(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      context "when provided a symbol" do

        let(:sum) do
          criteria.sum(:likes)
        end

        it "returns the sum of the provided field" do
          expect(sum).to eq(1500)
        end
      end

      context "when provided a block" do

        let(:sum) do
          criteria.sum(&:likes)
        end

        it "returns the sum for the provided block" do
          expect(sum).to eq(1500)
        end
      end
    end
  end

  describe "#to_ary" do

    let!(:band) do
      Band.create!(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "returns the executed criteria" do
      expect(criteria.to_ary).to eq([ band ])
    end
  end

  describe "#max_scan" do
    max_server_version '4.0'

    let!(:band) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:band2) do
      Band.create!(name: "Tool")
    end

    let(:criteria) do
      Band.where({}).max_scan(1)
    end

    it "executes the criteria while properly giving the max scan to Mongo" do
      expect(criteria.to_ary).to eq [band]
    end
  end

  describe "#to_criteria" do

    let(:criteria) do
      Band.all
    end

    it "returns self" do
      expect(criteria.to_criteria).to eq(criteria)
    end
  end

  describe "#to_proc" do

    let(:criteria) do
      Band.all
    end

    it "returns a proc" do
      expect(criteria.to_proc).to be_a(Proc)
    end

    it "wraps the criteria in the proc" do
      expect(criteria.to_proc[]).to eq(criteria)
    end
  end

  describe "#type" do
    context "when using the default discriminator_key" do
      context "when the type is a string" do

        let!(:browser) do
          Browser.create!
        end

        let(:criteria) do
          Canvas.all.type("Browser")
        end

        it "returns documents with the provided type" do
          expect(criteria).to eq([ browser ])
        end
      end

      context "when the type is an Array of type" do

        let!(:browser) do
          Firefox.create!
        end

        let(:criteria) do
          Canvas.all.type([ "Browser", "Firefox" ])
        end

        it "returns documents with the provided types" do
          expect(criteria).to eq([ browser ])
        end
      end
    end

    context "when using a custom discriminator_key" do
      before do
        Canvas.discriminator_key = "dkey"
      end

      after do
        Canvas.discriminator_key = nil
      end

      context "when the type is a string" do

        let!(:browser) do
          Browser.create!
        end

        let(:criteria) do
          Canvas.all.type("Browser")
        end

        it "returns documents with the provided type" do
          expect(criteria).to eq([ browser ])
        end
      end

      context "when the type is an Array of type" do

        let!(:browser) do
          Firefox.create!
        end

        let(:criteria) do
          Canvas.all.type([ "Browser", "Firefox" ])
        end

        it "returns documents with the provided types" do
          expect(criteria).to eq([ browser ])
        end
      end
    end
  end

  describe "#where" do

    let!(:match) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:non_match) do
      Band.create!(name: "Tool")
    end

    context 'when provided no arguments' do
      context 'on a model class' do
        it 'returns an empty criteria' do
          Band.where.selector.should == {}
        end
      end

      context 'on an association' do
        it 'returns an empty criteria' do
          match.records.where.selector.should == {}
        end
      end
    end

    context 'when provided multiple arguments' do
      context 'on a model class' do
        it 'raises ArgumentError' do
          lambda do
            Band.where({foo: 1}, {bar: 2})
          end.should raise_error(ArgumentError, /where requires zero or one arguments/)
        end
      end

      context 'on an association' do
        it 'raises ArgumentError' do
          lambda do
            match.records.where({foo: 1}, {bar: 2})
          end.should raise_error(ArgumentError, /where requires zero or one arguments/)
        end
      end
    end

    context "when provided a string" do

      context "when the criteria is embedded" do

        it "raises an error" do
          expect {
            match.records.where("this.name == null")
          }.to raise_error(Mongoid::Errors::UnsupportedJavascript)
        end
      end

      context "when the criteria is not embedded" do

        let(:criteria) do
          Band.where("this.name == 'Depeche Mode'")
        end

        it "returns the matching documents" do
          expect(criteria).to eq([ match ])
        end
      end
    end

    context "when provided criterion" do

      context "when the criteria is standard" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        it "returns the matching documents" do
          expect(criteria).to eq([ match ])
        end
      end

      context "when the criteria is an exact fk array match" do

        let(:id_one) do
          BSON::ObjectId.new
        end

        let(:id_two) do
          BSON::ObjectId.new
        end

        let(:criteria) do
          Account.where(agent_ids: [ id_one, id_two ])
        end

        it "does not wrap the array in another array" do
          expect(criteria.selector).to eq({ "agent_ids" => [ id_one, id_two ]})
        end
      end

      context "when querying on a big decimal" do

        context 'when map_big_decimal_to_decimal128 is false' do
          config_override :map_big_decimal_to_decimal128, false

          let(:sales) do
            BigDecimal('0.1')
          end

          let!(:band) do
            Band.create!(name: "Boards of Canada", sales: sales)
          end

          let(:from_db) do
            Band.where(sales: sales).first
          end

          it "finds the document by the big decimal value" do
            expect(from_db).to eq(band)
          end
        end

        context 'when map_big_decimal_to_decimal128 is true' do
          config_override :map_big_decimal_to_decimal128, true

          let(:sales) do
            BigDecimal('0.1')
          end

          let!(:band) do
            Band.create!(name: "Boards of Canada", sales: sales)
          end

          let(:from_db) do
            Band.where(sales: sales).first
          end

          it "finds the document by the big decimal value" do
            expect(from_db).to eq(band)
          end
        end

        context 'when map_big_decimal_to_decimal128 was false and is now true' do
          config_override :map_big_decimal_to_decimal128, false

          let(:sales) do
            BigDecimal('0.1')
          end

          let!(:band) do
            Mongoid.map_big_decimal_to_decimal128 = false
            Band.create!(name: "Boards of Canada", sales: sales)
          end

          let(:from_db) do
            Mongoid.map_big_decimal_to_decimal128 = true
            Band.where(sales: sales.to_s).first
          end

          it "finds the document by the big decimal value" do
            expect(from_db).to eq(band)
          end
        end
      end

      context "when querying on a big decimal from a dynamic field" do

        context 'when map_big_decimal_to_decimal128 is false' do
          config_override :map_big_decimal_to_decimal128, false

          let(:fans) do
            BigDecimal('139432.0002')
          end

          let!(:band) do
            Band.create!(name: "Boards of Canada", fans: fans)
          end

          let(:from_db) do
            Band.where(fans: fans.to_s).first
          end

          it "finds the document by the big decimal value" do
            expect(from_db).to eq(band)
          end
        end

        context 'when map_big_decimal_to_decimal128 is true' do
          config_override :map_big_decimal_to_decimal128, true

          let(:fans) do
            BigDecimal('139432.0002')
          end

          let!(:band) do
            Band.create!(name: "Boards of Canada", fans: fans)
          end

          let(:from_db) do
            Band.where(fans: fans).first
          end

          it "only finds the document by the string value" do
            expect(from_db).to eq(band)
          end
        end
      end

      context "when querying on a BSON::Decimal128" do
        min_server_version '3.4'

        let(:decimal) do
          BSON::Decimal128.new("0.0005")
        end

        let!(:band) do
          Band.create!(name: "Boards of Canada", decimal: decimal)
        end

        let(:from_db) do
          Band.where(decimal: decimal).first
        end

        it "finds the document by the big decimal value" do
          expect(from_db).to eq(band)
        end
      end

      context 'when querying on a polymorphic relation' do

        let(:movie) do
          Movie.create!
        end

        let(:selector) do
          Rating.where(ratable: movie).selector
        end

        it 'properly converts the object to an ObjectId' do
          expect(selector['ratable_id']).to eq(movie.id)
        end
      end
    end

    context 'when given multiple keys in separate calls' do
      let(:criteria) { Band.where(foo: 1).where(bar: 2) }

      it 'combines criteria' do
        expect(criteria.selector).to eq('foo' => 1, 'bar' => 2)
      end
    end

    context 'when given same key in separate calls' do
      let(:criteria) { Band.where(foo: 1).where(foo: 2) }

      it 'combines criteria' do
        expect(criteria.selector).to eq('foo' => 1, '$and' => [{'foo' => 2}])
      end
    end

    context 'when given same key in separate calls and there are other criteria' do
      let(:criteria) { Band.where(foo: 1, bar: 3).where(foo: 2) }

      it 'combines criteria' do
        expect(criteria.selector).to eq(
          'foo' => 1, '$and' => [{'foo' => 2}], 'bar' => 3)
      end
    end

    context 'when given same key in separate calls and other criteria are added later' do
      let(:criteria) { Band.where(foo: 1).where(foo: 2).where(bar: 3) }

      it 'combines criteria' do
        expect(criteria.selector).to eq(
          'foo' => 1, '$and' => [{'foo' => 2}], 'bar' => 3)
      end
    end

    context "when duplicating where conditions" do
      let(:criteria) { Sound.where(active: true).where(active: true) }

      it 'does not duplicate criteria' do
        expect(criteria.selector).to eq('active' => true)
      end
    end

    context "when duplicating where conditions with different values" do
      let(:criteria) { Sound.where(active: true).where(active: false).where(active: true).where(active: false) }

      it 'does not duplicate criteria' do
        expect(criteria.selector).to eq(
          'active' => true, '$and' => [{'active' => false}])
      end
    end

    # Used to test MONGOID-5251 where the find command was adding unnecessary
    # and clauses. Since the find command creates the criteria and executes it,
    # it is difficult to analyze the criteria used. For this reason, I have
    # extracted the crux of the issue, adding an _id to the the criteria twice,
    # and used that for the test case.
    context "when searching by _id twice" do
      let(:_id) { BSON::ObjectId.new }
      let(:criteria) { Band.where(_id: _id) }
      let(:dup_criteria) { criteria.where(_id: _id)}

      it "does not duplicate the criteria" do
        expect(dup_criteria.selector).to eq({ "_id" => _id })
      end
    end

    context "when querying an embedded field" do
      let(:criteria) { Band.where("label.name": 12345) }

      it "mongoizes the embedded field in the selector" do
        expect(criteria.selector).to eq("label.name" => "12345")
      end
    end

    context "when querying with a range" do

      context "when querying an embeds_many association" do
        let(:criteria) do
          Band.where("labels" => 10..15)
        end

        it "correctly uses elemMatch without an inner key" do
          expect(criteria.selector).to eq(
            "labels" => {
              "$elemMatch" => { "$gte" => 10, "$lte" => 15 }
            }
          )
        end
      end

      context "when querying an element in an embeds_many association" do
        let(:criteria) do
          Band.where("labels.age" => 10..15)
        end

        it "correctly uses elemMatch" do
          expect(criteria.selector).to eq(
            "labels" => {
              "$elemMatch" => {
                "age" => { "$gte" => 10, "$lte" => 15 }
              }
            }
          )
        end
      end

      context "when querying a field of type array" do
        let(:criteria) do
          Band.where("genres" => 10..15)
        end

        it "correctly uses elemMatch without an inner key" do
          expect(criteria.selector).to eq(
            "genres" => {
              "$elemMatch" => { "$gte" => 10, "$lte" => 15 }
            }
          )
        end
      end

      context "when querying an aliased field of type array" do
        let(:criteria) do
          Person.where("array" => 10..15)
        end

        it "correctly uses the aliased field and elemMatch" do
          expect(criteria.selector).to eq(
            "a" => {
              "$elemMatch" => { "$gte" => 10, "$lte" => 15 }
            }
          )
        end
      end

      context "when querying a field inside an array" do
        let(:criteria) do
          Band.where("genres.age" => 10..15)
        end

        it "correctly uses elemMatch" do
          expect(criteria.selector).to eq(
            "genres" => {
              "$elemMatch" => {
                "age" => { "$gte" => 10, "$lte" => 15 }
              }
            }
          )
        end
      end

      context "when there are no embeds_manys or Arrays" do
        let(:criteria) do
          Band.where("fans.info.age" => 10..15)
        end

        it "does not use elemMatch" do
          expect(criteria.selector).to eq(
            "fans.info.age" => { "$gte" => 10, "$lte" => 15 }
          )
        end
      end

      context "when querying a nested element in an embeds_many association" do
        let(:criteria) do
          Band.where("labels.age.number" => 10..15)
        end

        it "correctly uses elemMatch" do
          expect(criteria.selector).to eq(
            "labels" => {
              "$elemMatch" => {
                "age.number" => { "$gte" => 10, "$lte" => 15 }
              }
            }
          )
        end
      end

      context "when querying a nested element in an Array" do
        let(:criteria) do
          Band.where("genres.name.length" => 10..15)
        end

        it "correctly uses elemMatch" do
          expect(criteria.selector).to eq(
            "genres" => {
              "$elemMatch" => {
                "name.length" => { "$gte" => 10, "$lte" => 15 }
              }
            }
          )
        end
      end

      context "when querying a nested element in a nested embeds_many association" do
        context "when the outer association is an embeds_many" do
          let(:criteria) do
            Band.where("records.tracks.name.length" => 10..15)
          end

          it "correctly uses elemMatch" do
            expect(criteria.selector).to eq(
              "records.tracks" => {
                "$elemMatch" => {
                  "name.length" => { "$gte" => 10, "$lte" => 15 }
                }
              }
            )
          end
        end

        context "when the outer association is an embeds_one" do
          let(:criteria) do
            Person.where("name.translations.language.length" => 10..15)
          end

          it "correctly uses elemMatch" do
            expect(criteria.selector).to eq(
              "name.translations" => {
                "$elemMatch" => {
                  "language.length" => { "$gte" => 10, "$lte" => 15 }
                }
              }
            )
          end
        end
      end

      context "when querying a deeply nested array" do
        let(:criteria) do
          Person.where("addresses.code.deepest.array.element.item" => 10..15)
        end

        it "correctly uses elemMatch" do
          expect(criteria.selector).to eq(
            "addresses.code.deepest.array" => {
              "$elemMatch" => {
                "element.item" => { "$gte" => 10, "$lte" => 15 }
              }
            }
          )
        end
      end

      context "when there are multiple conditions" do
        let(:criteria) do
          Band.where("$or" => [{"labels.age" => 10..15}, {labels: 8}])
        end

        it "correctly combines the conditions" do
          expect(criteria.selector).to eq("$or" => [
            { "labels" => {
              "$elemMatch" => {
                "age" => { "$gte" => 10, "$lte" => 15 }
              } } },
            { "labels" => 8 }
          ])
        end
      end

      context "when the association is aliased" do
        let(:criteria) do
          Person.where("passport.passport_pages.num_stamps" => 10..18)
        end

        it "correctly uses the aliased association" do
          expect(criteria.selector).to eq(
            "pass.passport_pages" => {
              "$elemMatch" => {
                "num_stamps" => { "$gte" => 10, "$lte" => 18 }
              }
            }
          )
        end
      end
    end
  end

  describe "#for_js" do

    let!(:match) do
      Band.create!(name: "Depeche Mode")
    end

    context "when the code has no scope" do

      let(:criteria) do
        Band.for_js("this.name == 'Depeche Mode'")
      end

      it "returns the matching documents" do
        expect(criteria).to eq([ match ])
      end
    end

    context "when the code has scope" do
      max_server_version '4.2'

      let(:criteria) do
        Band.for_js("this.name == param", param: "Depeche Mode")
      end

      it "returns the matching documents" do
        expect(criteria).to eq([ match ])
      end
    end
  end

  describe "#method_missing" do

    let(:criteria) do
      Person.all
    end

    context "when the method exists on the class" do

      before do
        expect(Person).to receive(:minor).and_call_original
        expect(Person).to receive(:older_than).and_call_original
      end

      it "calls the method on the class" do
        expect(criteria.minor).to be_empty
        expect do
          criteria.older_than(age: 25)
        end.not_to raise_error
      end
    end

    context "when the method exists on the criteria" do

      before do
        expect(criteria).to receive(:to_criteria).and_call_original
      end

      it "calls the method on the criteria" do
        expect(criteria.to_criteria).to eq(criteria)
      end
    end

    context "when the method exists on array" do

      before do
        expect(criteria).to receive(:entries).and_call_original
      end

      it "calls the method on the criteria" do
        expect(criteria.at(0)).to be_nil
      end
    end

    context "when the method does not exist" do

      before do
        expect(criteria).to receive(:entries).never
      end

      it "raises an error" do
        expect {
          criteria.to_hash
        }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#uniq" do

    let!(:band_one) do
      Band.create!(name: "New Order")
    end

    let!(:band_two) do
      Band.create!(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    it "passes the block through method_missing" do
      expect(criteria.uniq(&:name)).to eq([ band_one ])
    end
  end

  describe "#with" do

    let!(:criteria_and_collection) do
      collection = nil
      criteria = Band.where(name: "Depeche Mode").with(collection: "artists") do |crit|
        collection = crit.collection
        crit
      end
      [ criteria, collection ]
    end

    let(:criteria) do
      criteria_and_collection[0]
    end

    let(:collection) do
      criteria_and_collection[1]
    end

    it "retains the criteria selection" do
      expect(criteria.selector).to eq("name" => "Depeche Mode")
    end

    it "sets the persistence options" do
      expect(collection.name).to eq("artists")
    end
  end

  describe "#geo_spatial" do

    context "when checking within a polygon" do

      before do
        Bar.create_indexes
      end

      let!(:match) do
        Bar.create!(location: [ 52.30, 13.25 ])
      end

      let(:criteria) do
        Bar.geo_spatial(
          :location.within_polygon => [[[ 50, 10 ], [ 50, 20 ], [ 60, 20 ], [ 60, 10 ], [ 50, 10 ]]]
        )
      end

      it "returns the matching documents" do
        expect(criteria).to eq([ match ])
      end
    end
  end

  describe "#with_size" do

    let!(:match) do
      Band.create!(genres: [ "electro", "dub" ])
    end

    let!(:non_match) do
      Band.create!(genres: [ "house" ])
    end

    let(:criteria) do
      Band.with_size(genres: 2)
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#with_type" do

    let!(:match) do
      Band.create!(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.with_type(name: 2)
    end

    it "returns the matching documents" do
      expect(criteria).to eq([ match ])
    end
  end

  describe "#type_selection" do
    context "when using the default discriminator_key" do
      context "when only one subclass exists" do

        let(:criteria) do
          described_class.new(Firefox)
        end

        let(:selection) do
          criteria.send(:type_selection)
        end

        it "does not use an $in query" do
          expect(selection).to eq({ _type: "Firefox" })
        end
      end

      context "when more than one subclass exists" do

        let(:criteria) do
          described_class.new(Browser)
        end

        let(:selection) do
          criteria.send(:type_selection)
        end

        it "does not use an $in query" do
          expect(selection).to eq({ _type: { "$in" => [ "Firefox", "Browser" ]}})
        end
      end
    end

    context "when using a custom discriminator_key" do
      before do
        Canvas.discriminator_key = "dkey"
      end

      after do
        Canvas.discriminator_key = nil
      end

      context "when only one subclass exists" do

        let(:criteria) do
          described_class.new(Firefox)
        end

        let(:selection) do
          criteria.send(:type_selection)
        end

        it "does not use an $in query" do
          expect(selection).to eq({ dkey: "Firefox" })
        end
      end

      context "when more than one subclass exists" do

        let(:criteria) do
          described_class.new(Browser)
        end

        let(:selection) do
          criteria.send(:type_selection)
        end

        it "does not use an $in query" do
          expect(selection).to eq({ dkey: { "$in" => [ "Firefox", "Browser" ]}})
        end
      end
    end
  end
end
