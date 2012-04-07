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
          criteria.should eq(other)
        end
      end

      context "when the criteria differ" do

        let(:other) do
          Band.where(name: "Tool")
        end

        it "returns false" do
          criteria.should_not eq(other)
        end
      end
    end

    context "when the other is an enumerable" do

      context "when the entries are the same" do

        let!(:band) do
          Band.create(name: "Depeche Mode")
        end

        let(:other) do
          [ band ]
        end

        it "returns true" do
          criteria.should eq(other)
        end
      end

      context "when the entries are not the same" do

        let!(:band) do
          Band.create(name: "Depeche Mode")
        end

        let!(:other_band) do
          Band.create(name: "Tool")
        end

        let(:other) do
          [ other_band ]
        end

        it "returns false" do
          criteria.should_not eq(other)
        end
      end
    end

    context "when the other is neither a criteria or enumerable" do

      it "returns false" do
        criteria.should_not eq("test")
      end
    end
  end

  describe "#===" do

    context "when the other is a criteria" do

      let(:other) do
        Band.where(name: "Depeche Mode")
      end

      it "returns true" do
        (described_class === other).should be_true
      end
    end

    context "when the other is not a criteria" do

      it "returns false" do
        (described_class === []).should be_false
      end
    end
  end

  describe "#aggregates" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      let(:aggregates) do
        criteria.aggregates(:likes)
      end

      it "returns an avg" do
        aggregates["avg"].should eq(750)
      end

      it "returns a count" do
        aggregates["count"].should eq(2)
      end

      it "returns a max" do
        aggregates["max"].should eq(1000)
      end

      it "returns a min" do
        aggregates["min"].should eq(500)
      end

      it "returns a sum" do
        aggregates["sum"].should eq(1500)
      end
    end
  end

  describe "#avg" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      let(:avg) do
        criteria.avg(:likes)
      end

      it "returns the avg of the provided field" do
        avg.should eq(750)
      end
    end
  end

  [ :all, :all_in ].each do |method|

    describe "\##{method}" do

      let!(:match) do
        Band.create(genres: [ "electro", "dub" ])
      end

      let!(:non_match) do
        Band.create(genres: [ "house" ])
      end

      let(:criteria) do
        Band.send(method, genres: [ "electro", "dub" ])
      end

      it "returns the matching documents" do
        criteria.should eq([ match ])
      end
    end
  end

  [ :and, :all_of ].each do |method|

    describe "\##{method}" do

      let!(:match) do
        Band.create(name: "Depeche Mode", genres: [ "electro" ])
      end

      let!(:non_match) do
        Band.create(genres: [ "house" ])
      end

      let(:criteria) do
        Band.send(method, { genres: "electro" }, { name: "Depeche Mode" })
      end

      it "returns the matching documents" do
        criteria.should eq([ match ])
      end
    end
  end

  describe "#as_json" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "returns the criteria as a json hash" do
      criteria.as_json.should eq([ band.serializable_hash ])
    end
  end

  describe "#between" do

    let!(:match) do
      Band.create(member_count: 3)
    end

    let!(:non_match) do
      Band.create(member_count: 10)
    end

    let(:criteria) do
      Band.between(member_count: 1..5)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#build" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    context "when provided valid attributes" do

      let(:band) do
        criteria.build(genres: [ "electro" ])
      end

      it "returns the new document" do
        band.should be_new_record
      end

      it "sets the criteria attributes" do
        band.name.should eq("Depeche Mode")
      end

      it "sets the attributes passed to build" do
        band.genres.should eq([ "electro" ])
      end
    end
  end

  [ :clone, :dup ].each do |method|

    describe "\##{method}" do

      let(:band) do
        Band.new
      end

      let(:criteria) do
        Band.where(name: "Depeche Mode").asc(:name).includes(:records)
      end

      before do
        criteria.documents = [ band ]
        criteria.context
      end

      let(:clone) do
        criteria.send(method)
      end

      it "contains an equal selector" do
        clone.selector.should eq({ "name" => "Depeche Mode" })
      end

      it "clones the selector" do
        clone.selector.should_not equal(criteria.selector)
      end

      it "contains equal options" do
        clone.options.should eq({ sort: { "name" => 1 }})
      end

      it "clones the options" do
        clone.options.should_not equal(criteria.options)
      end

      it "contains equal inclusions" do
        clone.inclusions.should eq([ Band.relations["records"] ])
      end

      it "clones the inclusions" do
        clone.inclusions.should_not equal(criteria.inclusions)
      end

      it "contains equal documents" do
        clone.documents.should eq([ band ])
      end

      it "clones the documents" do
        clone.documents.should_not equal(criteria.documents)
      end

      it "contains equal scoping options" do
        clone.scoping_options.should eq([ nil, nil ])
      end

      it "clones the scoping options" do
        clone.scoping_options.should_not equal(criteria.scoping_options)
      end

      it "sets the context to nil" do
        clone.instance_variable_get(:@context).should be_nil
      end
    end
  end

  describe "#cache" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "sets the cache option to true" do
      criteria.cache.should be_cached
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
        criteria.context.should be_a(Mongoid::Contextual::Memory)
      end
    end

    context "when the model is not embedded" do

      let(:criteria) do
        described_class.new(Band)
      end

      it "returns the mongo context" do
        criteria.context.should be_a(Mongoid::Contextual::Mongo)
      end
    end
  end

  describe "#create" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    context "when provided valid attributes" do

      let(:band) do
        criteria.create(genres: [ "electro" ])
      end

      it "returns the created document" do
        band.should be_persisted
      end

      it "sets the criteria attributes" do
        band.name.should eq("Depeche Mode")
      end

      it "sets the attributes passed to build" do
        band.genres.should eq([ "electro" ])
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
      criteria.documents.should eq([ band ])
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
      criteria.documents.should eq([ band ])
    end
  end

  describe "#each" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    context "when provided a block" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      it "iterates over the matching documents" do
        criteria.each do |doc|
          doc.should eq(band)
        end
      end
    end
  end

  describe "#elem_match" do

    let!(:match) do
      Band.create(name: "Depeche Mode").tap do |band|
        band.records.create(name: "101")
      end
    end

    let!(:non_match) do
      Band.create(genres: [ "house" ])
    end

    let(:criteria) do
      Band.elem_match(records: { name: "101" })
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#exists" do

    let!(:match) do
      Band.create(name: "Depeche Mode")
    end

    let!(:non_match) do
      Band.create
    end

    let(:criteria) do
      Band.exists(name: true)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#exists?" do

    context "when matching documents exist" do

      let!(:match) do
        Band.create(name: "Depeche Mode")
      end

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      it "returns true" do
        criteria.exists?.should be_true
      end
    end

    context "when no matching documents exist" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      it "returns false" do
        criteria.exists?.should be_false
      end
    end
  end

  pending "#explain" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "returns the criteria explain path" do
      criteria.explain["cursor"].should eq("BasicCursor")
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
        criteria.extract_id.should eq(id)
      end
    end

    context "when an _id exists" do

      let(:criteria) do
        described_class.new(Band) do |criteria|
          criteria.selector[:_id] = id
        end
      end

      it "returns the _id" do
        criteria.extract_id.should eq(id)
      end
    end
  end

  describe "#field_list" do

    let(:criteria) do
      Band.only(:name)
    end

    it "returns the fields minus type" do
      criteria.field_list.should eq([ "name" ])
    end
  end

  describe "#find" do

    context "when using object ids" do

      let!(:band) do
        Band.create
      end

      context "when providing a single id" do

        context "when the id matches" do

          let(:found) do
            Band.find(band.id)
          end

          it "returns the matching document" do
            found.should eq(band)
          end
        end

        context "when the id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(BSON::ObjectId.new)
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(BSON::ObjectId.new)
            end

            it "returns nil" do
              found.should be_nil
            end
          end
        end
      end

      context "when providing a splat of ids" do

        let!(:band_two) do
          Band.create(name: "Tool")
        end

        context "when all ids match" do

          let(:found) do
            Band.find(band.id, band_two.id)
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(band.id, BSON::ObjectId.new)
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(band.id, BSON::ObjectId.new)
            end

            it "returns only the matching documents" do
              found.should eq([ band ])
            end
          end
        end
      end

      context "when providing an array of ids" do

        let!(:band_two) do
          Band.create(name: "Tool")
        end

        context "when all ids match" do

          let(:found) do
            Band.find([ band.id, band_two.id ])
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find([ band.id, BSON::ObjectId.new ])
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find([ band.id, BSON::ObjectId.new ])
            end

            it "returns only the matching documents" do
              found.should eq([ band ])
            end
          end
        end
      end
    end

    context "when using string ids" do

      before(:all) do
        Band.field :_id, type: String
      end

      after(:all) do
        Band.field :_id, type: BSON::ObjectId, default: ->{ BSON::ObjectId.new }
      end

      let!(:band) do
        Band.create do |band|
          band.id = "tool"
        end
      end

      context "when providing a single id" do

        context "when the id matches" do

          let(:found) do
            Band.find(band.id)
          end

          it "returns the matching document" do
            found.should eq(band)
          end
        end

        context "when the id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find("depeche-mode")
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find("depeche-mode")
            end

            it "returns nil" do
              found.should be_nil
            end
          end
        end
      end

      context "when providing a splat of ids" do

        let!(:band_two) do
          Band.create do |band|
            band.id = "depeche-mode"
          end
        end

        context "when all ids match" do

          let(:found) do
            Band.find(band.id, band_two.id)
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(band.id, "new-order")
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(band.id, "new-order")
            end

            it "returns only the matching documents" do
              found.should eq([ band ])
            end
          end
        end
      end

      context "when providing an array of ids" do

        let!(:band_two) do
          Band.create do |band|
            band.id = "depeche-mode"
          end
        end

        context "when all ids match" do

          let(:found) do
            Band.find([ band.id, band_two.id ])
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find([ band.id, "new-order" ])
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find([ band.id, "new-order" ])
            end

            it "returns only the matching documents" do
              found.should eq([ band ])
            end
          end
        end
      end
    end

    context "when using integer ids" do

      before(:all) do
        Band.field :_id, type: Integer
      end

      after(:all) do
        Band.field :_id, type: BSON::ObjectId, default: ->{ BSON::ObjectId.new }
      end

      let!(:band) do
        Band.create do |band|
          band.id = 1
        end
      end

      context "when providing a single id" do

        context "when the id matches" do

          let(:found) do
            Band.find(band.id)
          end

          it "returns the matching document" do
            found.should eq(band)
          end
        end

        context "when the id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(3)
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(3)
            end

            it "returns nil" do
              found.should be_nil
            end
          end
        end
      end

      context "when providing a splat of ids" do

        let!(:band_two) do
          Band.create do |band|
            band.id = 2
          end
        end

        context "when all ids match" do

          let(:found) do
            Band.find(band.id, band_two.id)
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(band.id, 3)
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(band.id, 3)
            end

            it "returns only the matching documents" do
              found.should eq([ band ])
            end
          end
        end
      end

      context "when providing an array of ids" do

        let!(:band_two) do
          Band.create do |band|
            band.id = 2
          end
        end

        context "when all ids match" do

          let(:found) do
            Band.find([ band.id, band_two.id ])
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find([ band.id, 3 ])
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find([ band.id, 3 ])
            end

            it "returns only the matching documents" do
              found.should eq([ band ])
            end
          end
        end
      end

      context "when providing a range" do

        let!(:band_two) do
          Band.create do |band|
            band.id = 2
          end
        end

        context "when all ids match" do

          let(:found) do
            Band.find(1..2)
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(1..3)
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(1..3)
            end

            it "contains the first match" do
              found.should include(band)
            end

            it "contains the second match" do
              found.should include(band_two)
            end

            it "returns only the matches" do
              found.count.should eq(2)
            end
          end
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
      criteria.should be_frozen
    end

    it "initializes inclusions" do
      criteria.inclusions.should be_empty
    end

    it "initializes the context" do
      criteria.context.should_not be_nil
    end
  end

  describe "#from_map_or_db" do

    before(:all) do
      Mongoid.identity_map_enabled = true
    end

    after(:all) do
      Mongoid.identity_map_enabled = false
    end

    context "when the document is in the identity map" do

      let!(:band) do
        Band.create(name: "Depeche Mode")
      end

      let(:criteria) do
        Band.where(_id: band.id)
      end

      let(:from_map) do
        criteria.from_map_or_db
      end

      it "returns the document from the map" do
        from_map.should equal(band)
      end
    end

    context "when the document is not in the identity map" do

      let!(:band) do
        Band.create(name: "Depeche Mode")
      end

      let(:criteria) do
        Band.where(_id: band.id)
      end

      before do
        Mongoid::IdentityMap.clear
      end

      let(:from_db) do
        criteria.from_map_or_db
      end

      it "returns the document from the database" do
        from_db.should_not equal(band)
      end

      it "returns the correct document" do
        from_db.should eq(band)
      end
    end
  end

  describe "#multiple_from_map_or_db" do

    before(:all) do
      Mongoid.identity_map_enabled = true
    end

    after(:all) do
      Mongoid.identity_map_enabled = false
    end

    context "when the document is in the identity map" do

      let!(:band) do
        Band.create(name: "Depeche Mode")
      end

      let!(:band_two) do
        Band.create(name: "Tool")
      end

      context "when providing a single id" do

        let(:criteria) do
          Band.where(_id: band.id)
        end

        let(:from_map) do
          criteria.multiple_from_map_or_db([ band.id ])
        end

        it "returns the document from the map" do
          from_map.should include(band)
        end
      end

      context "when providing multiple ids" do

        let(:criteria) do
          Band.where(:_id.in => [ band.id, band_two.id ])
        end

        let(:from_map) do
          criteria.multiple_from_map_or_db([ band.id, band_two.id ])
        end

        it "returns the documents from the map" do
          from_map.should include(band, band_two)
        end
      end
    end

    context "when the document is not in the identity map" do

      let!(:band) do
        Band.create(name: "Depeche Mode")
      end

      let!(:band_two) do
        Band.create(name: "Tool")
      end

      before do
        Mongoid::IdentityMap.clear
      end

      context "when providing a single id" do

        let(:criteria) do
          Band.where(_id: band.id)
        end

        let(:from_db) do
          criteria.multiple_from_map_or_db([ band.id ])
        end

        it "returns the document from the database" do
          from_db.first.should_not equal(band)
        end

        it "returns the correct document" do
          from_db.first.should eq(band)
        end
      end

      context "when providing multiple ids" do

        let(:criteria) do
          Band.where(:_id.in => [ band.id, band_two.id ])
        end

        let(:from_db) do
          criteria.multiple_from_map_or_db([ band.id, band_two.id ])
        end

        it "returns the document from the database" do
          from_db.first.should_not equal(band)
        end

        it "returns the correct document" do
          from_db.first.should eq(band)
        end
      end
    end
  end

  describe "$gt" do

    let!(:match) do
      Band.create(member_count: 5)
    end

    let!(:non_match) do
      Band.create(member_count: 1)
    end

    let(:criteria) do
      Band.gt(member_count: 4)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "$gte" do

    let!(:match) do
      Band.create(member_count: 5)
    end

    let!(:non_match) do
      Band.create(member_count: 1)
    end

    let(:criteria) do
      Band.gte(member_count: 5)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  [ :in, :any_in ].each do |method|

    describe "\##{method}" do

      let!(:match) do
        Band.create(genres: [ "electro", "dub" ])
      end

      let!(:non_match) do
        Band.create(genres: [ "house" ])
      end

      let(:criteria) do
        Band.send(method, genres: [ "dub" ])
      end

      it "returns the matching documents" do
        criteria.should eq([ match ])
      end
    end
  end

  describe "#initialize" do

    let(:criteria) do
      described_class.new(Band)
    end

    it "sets the class" do
      criteria.klass.should eq(Band)
    end

    it "sets the aliased fields" do
      criteria.aliased_fields.should eq(Band.aliased_fields)
    end

    it "sets the serializers" do
      criteria.serializers.should eq(Band.fields)
    end
  end

  describe "#includes" do

    before do
      Mongoid.identity_map_enabled = true
    end

    after do
      Mongoid.identity_map_enabled = false
    end

    let!(:person) do
      Person.create
    end

    context "when providing inclusions to the default scope" do

      before do
        Person.default_scope(Person.includes(:posts))
      end

      after do
        Person.default_scoping = nil
      end

      let!(:post_one) do
        person.posts.create(title: "one")
      end

      let!(:post_two) do
        person.posts.create(title: "two")
      end

      context "when the criteria has no options" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.all.entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when calling first on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.first
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when calling last on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.last
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create
        end

        let!(:post_three) do
          person_two.posts.create(title: "three")
        end

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.asc(:_id).limit(1).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end

        it "does not insert the third post into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_three.id].should be_nil
        end
      end
    end

    context "when including a has and belongs to many" do

      let!(:preference_one) do
        person.preferences.create(name: "one")
      end

      let!(:preference_two) do
        person.preferences.create(name: "two")
      end

      context "when the criteria has no options" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:preferences).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        let(:preference_map) do
          Mongoid::IdentityMap[Preference.collection_name]
        end

        it "inserts the first document into the identity map" do
          preference_map[preference_one.id].should eq(preference_one)
        end

        it "inserts the second document into the identity map" do
          preference_map[preference_two.id].should eq(preference_two)
        end
      end

      context "when calling first on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.includes(:preferences).first
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        let(:preference_map) do
          Mongoid::IdentityMap[Preference.collection_name]
        end

        it "inserts the first document into the identity map" do
          preference_map[preference_one.id].should eq(preference_one)
        end

        it "inserts the second document into the identity map" do
          preference_map[preference_two.id].should eq(preference_two)
        end
      end

      context "when calling last on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.includes(:preferences).last
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        let(:preference_map) do
          Mongoid::IdentityMap[Preference.collection_name]
        end

        it "inserts the first document into the identity map" do
          preference_map[preference_one.id].should eq(preference_one)
        end

        it "inserts the second document into the identity map" do
          preference_map[preference_two.id].should eq(preference_two)
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create
        end

        let!(:preference_three) do
          person_two.preferences.create(name: "three")
        end

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:preferences).asc(:_id).limit(1).entries
        end

        let(:preference_map) do
          Mongoid::IdentityMap[Preference.collection_name]
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          preference_map[preference_one.id].should eq(preference_one)
        end

        it "inserts the second document into the identity map" do
          preference_map[preference_two.id].should eq(preference_two)
        end

        it "does not insert the third preference into the identity map" do
          preference_map[preference_three.id].should be_nil
        end
      end
    end

    context "when including a has many" do

      let!(:post_one) do
        person.posts.create(title: "one")
      end

      let!(:post_two) do
        person.posts.create(title: "two")
      end

      context "when the criteria has no options" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:posts).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when calling first on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.includes(:posts).first
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when calling last on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.includes(:posts).last
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create
        end

        let!(:post_three) do
          person_two.posts.create(title: "three")
        end

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:posts).asc(:_id).limit(1).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end

        it "does not insert the third post into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_three.id].should be_nil
        end
      end
    end

    context "when including a has one" do

      let!(:game_one) do
        person.create_game(name: "one")
      end

      let!(:game_two) do
        person.create_game(name: "two")
      end

      context "when the criteria has no options" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:game).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "deletes the replaced document from the identity map" do
          Mongoid::IdentityMap[Game.collection_name][game_one.id].should be_nil
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Game.collection_name][game_two.id].should eq(game_two)
        end

        context "when asking from map or db" do

          let(:in_map) do
            Mongoid::IdentityMap[Game.collection_name][game_two.id]
          end

          let(:game) do
            Game.where("person_id" => person.id).from_map_or_db
          end

          it "returns the document from the map" do
            game.should equal(in_map)
          end
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create
        end

        let!(:game_three) do
          person_two.create_game(name: "Skyrim")
        end

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:game).asc(:_id).limit(1).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Game.collection_name][game_two.id].should eq(game_two)
        end

        it "does not load the extra child into the map" do
          Mongoid::IdentityMap[Game.collection_name][game_three.id].should be_nil
        end
      end
    end

    context "when including a belongs to" do

      let(:person_two) do
        Person.create
      end

      let!(:game_one) do
        person.create_game(name: "one")
      end

      let!(:game_two) do
        person_two.create_game(name: "two")
      end

      before do
        Mongoid::IdentityMap.clear
      end

      context "when providing no options" do

        let!(:criteria) do
          Game.includes(:person).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ game_one, game_two ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Person.collection_name][person.id].should eq(person)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Person.collection_name][person_two.id].should eq(person_two)
        end
      end

      context "when the criteria has limiting options" do

        let!(:criteria) do
          Game.includes(:person).asc(:_id).limit(1).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ game_one ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Person.collection_name][person.id].should eq(person)
        end

        it "does not load the documents outside of the limit" do
          Mongoid::IdentityMap[Person.collection_name][person_two.id].should be_nil
        end
      end
    end

    context "when including multiples in the same criteria" do

      let!(:post_one) do
        person.posts.create(title: "one")
      end

      let!(:post_two) do
        person.posts.create(title: "two")
      end

      let!(:game_one) do
        person.create_game(name: "one")
      end

      let!(:game_two) do
        person.create_game(name: "two")
      end

      before do
        Mongoid::IdentityMap.clear
      end

      let!(:criteria) do
        Person.includes(:posts, :game).entries
      end

      it "returns the correct documents" do
        criteria.should eq([ person ])
      end

      it "inserts the first has many document into the identity map" do
        Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
      end

      it "inserts the second has many document into the identity map" do
        Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
      end

      it "removes the first has one document from the identity map" do
        Mongoid::IdentityMap[Game.collection_name][game_one.id].should be_nil
      end

      it "inserts the second has one document into the identity map" do
        Mongoid::IdentityMap[Game.collection_name][game_two.id].should eq(game_two)
      end
    end
  end

  describe "#inclusions" do

    let(:criteria) do
      Band.includes(:records)
    end

    let(:metadata) do
      Band.relations["records"]
    end

    it "returns the inclusions" do
      criteria.inclusions.should eq([ metadata ])
    end
  end

  describe "#inclusions=" do

    let(:criteria) do
      Band.all
    end

    let(:metadata) do
      Band.relations["records"]
    end

    before do
      criteria.inclusions = [ metadata ]
    end

    it "sets the inclusions" do
      criteria.inclusions.should eq([ metadata ])
    end
  end

  describe "#lt" do

    let!(:match) do
      Band.create(member_count: 1)
    end

    let!(:non_match) do
      Band.create(member_count: 5)
    end

    let(:criteria) do
      Band.lt(member_count: 4)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#lte" do

    let!(:match) do
      Band.create(member_count: 4)
    end

    let!(:non_match) do
      Band.create(member_count: 5)
    end

    let(:criteria) do
      Band.lte(member_count: 4)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
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
      Band.create(name: "Depeche Mode", likes: 200)
    end

    let!(:tool) do
      Band.create(name: "Tool", likes: 100)
    end

    let(:map_reduce) do
      Band.limit(2).map_reduce(map, reduce).out(inline: 1)
    end

    it "returns the map/reduce results" do
      map_reduce.should eq([
        { "_id" => "Depeche Mode", "value" => { "likes" => 200 }},
        { "_id" => "Tool", "value" => { "likes" => 100 }}
      ])
    end
  end

  describe "#max" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      context "when provided a symbol" do

        let(:max) do
          criteria.max(:likes)
        end

        it "returns the max of the provided field" do
          max.should eq(1000)
        end
      end

      context "when provided a block" do

        let(:max) do
          criteria.max do |a, b|
            a.likes <=> b.likes
          end
        end

        it "returns the document with the max value for the field" do
          max.should eq(depeche)
        end
      end
    end
  end

  describe "#max_distance" do

    before do
      Bar.create_indexes
    end

    let!(:match) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let!(:non_match) do
      Bar.create(location: [ 19.26, 99.70 ])
    end

    let(:criteria) do
      Bar.near(location: [ 52, 13 ]).max_distance(location: 5)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#merge" do

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

    let(:metadata) do
      Band.relations["records"]
    end

    let(:merged) do
      criteria.merge(mergeable)
    end

    it "merges the selector" do
      merged.selector.should eq({ "name" => "Depeche Mode" })
    end

    it "merges the options" do
      merged.options.should eq({ sort: { "name" => 1 }})
    end

    it "merges the documents" do
      merged.documents.should eq([ band ])
    end

    it "merges the scoping options" do
      merged.scoping_options.should eq([ nil, nil ])
    end

    it "merges the inclusions" do
      merged.inclusions.should eq([ metadata ])
    end

    it "returns a new criteria" do
      merged.should_not equal(criteria)
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

    let(:metadata) do
      Band.relations["records"]
    end

    let(:merged) do
      criteria.merge!(mergeable)
    end

    it "merges the selector" do
      merged.selector.should eq({ "name" => "Depeche Mode" })
    end

    it "merges the options" do
      merged.options.should eq({ sort: { "name" => 1 }})
    end

    it "merges the documents" do
      merged.documents.should eq([ band ])
    end

    it "merges the scoping options" do
      merged.scoping_options.should eq([ nil, nil ])
    end

    it "merges the inclusions" do
      merged.inclusions.should eq([ metadata ])
    end

    it "returns the same criteria" do
      merged.should equal(criteria)
    end
  end

  describe "#min" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      context "when provided a symbol" do

        let(:min) do
          criteria.min(:likes)
        end

        it "returns the min of the provided field" do
          min.should eq(500)
        end
      end

      context "when provided a block" do

        let(:min) do
          criteria.min do |a, b|
            a.likes <=> b.likes
          end
        end

        it "returns the document with the min value for the field" do
          min.should eq(tool)
        end
      end
    end
  end

  describe "#mod" do

    let!(:match) do
      Band.create(member_count: 5)
    end

    let!(:non_match) do
      Band.create(member_count: 2)
    end

    let(:criteria) do
      Band.mod(member_count: [ 4, 1 ])
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#ne" do

    let!(:match) do
      Band.create(name: "Depeche Mode")
    end

    let!(:non_match) do
      Band.create(name: "Tool")
    end

    let(:criteria) do
      Band.ne(name: "Tool")
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#near" do

    before do
      Bar.create_indexes
    end

    let!(:match) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let(:criteria) do
      Bar.near(location: [ 52, 13 ])
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#near_sphere" do

    before do
      Bar.create_indexes
    end

    let!(:match) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let(:criteria) do
      Bar.near_sphere(location: [ 52, 13 ])
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#nin" do

    let!(:match) do
      Band.create(name: "Depeche Mode")
    end

    let!(:non_match) do
      Band.create(name: "Tool")
    end

    let(:criteria) do
      Band.nin(name: [ "Tool" ])
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#nor" do

    let!(:match) do
      Band.create(name: "Depeche Mode")
    end

    let!(:non_match) do
      Band.create(name: "Tool")
    end

    let(:criteria) do
      Band.nor({ name: "Tool" }, { name: "New Order" })
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#only" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.only(:_id)
    end

    it "limits the returned fields" do
      criteria.first.name.should be_nil
    end
  end

  [ :or, :any_of ].each do |method|

    describe "\##{method}" do

      let!(:match) do
        Band.create(name: "Depeche Mode")
      end

      let!(:non_match) do
        Band.create(name: "Tool")
      end

      let(:criteria) do
        Band.send(method, { name: "Depeche Mode" }, { name: "New Order" })
      end

      it "returns the matching documents" do
        criteria.should eq([ match ])
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
        criteria.should respond_to(:ages)
      end
    end

    context "when asking about a model private class method" do

      context "when including private methods" do

        it "returns true" do
          criteria.respond_to?(:for_ids, true).should be_true
        end
      end
    end

    context "when asking about a model class public instance method" do

      it "returns true" do
        criteria.respond_to?(:join).should be_true
      end
    end

    context "when asking about a model private instance method" do

      context "when not including private methods" do

        it "returns false" do
          criteria.should_not respond_to(:fork)
        end
      end

      context "when including private methods" do

        it "returns true" do
          criteria.respond_to?(:fork, true).should be_true
        end
      end
    end

    context "when asking about a criteria instance method" do

      it "returns true" do
        criteria.should respond_to(:context)
      end
    end

    context "when asking about a private criteria instance method" do

      context "when not including private methods" do

        it "returns false" do
          criteria.should_not respond_to(:puts)
        end
      end

      context "when including private methods" do

        it "returns true" do
          criteria.respond_to?(:puts, true).should be_true
        end
      end
    end
  end

  describe "#sum" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      context "when provided a symbol" do

        let(:sum) do
          criteria.sum(:likes)
        end

        it "returns the sum of the provided field" do
          sum.should eq(1500)
        end
      end

      context "when provided a block" do

        let(:sum) do
          criteria.sum(&:likes)
        end

        it "returns the sum for the provided block" do
          sum.should eq(1500)
        end
      end
    end
  end

  describe "#to_ary" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "returns the executed criteria" do
      criteria.to_ary.should eq([ band ])
    end
  end

  describe "#to_criteria" do

    let(:criteria) do
      Band.all
    end

    it "returns self" do
      criteria.to_criteria.should eq(criteria)
    end
  end

  describe "#to_proc" do

    let(:criteria) do
      Band.all
    end

    it "returns a proc" do
      criteria.to_proc.should be_a(Proc)
    end

    it "wraps the criteria in the proc" do
      criteria.to_proc[].should eq(criteria)
    end
  end

  describe "#type" do

    context "when the type is a string" do

      let!(:browser) do
        Browser.create
      end

      let(:criteria) do
        Canvas.all.type("Browser")
      end

      it "returns documents with the provided type" do
        criteria.should eq([ browser ])
      end
    end

    context "when the type is an Array of type" do

      let!(:browser) do
        Firefox.create
      end

      let(:criteria) do
        Canvas.all.type([ "Browser", "Firefox" ])
      end

      it "returns documents with the provided types" do
        criteria.should eq([ browser ])
      end
    end
  end

  describe "#where" do

    let!(:match) do
      Band.create(name: "Depeche Mode")
    end

    let!(:non_match) do
      Band.create(name: "Tool")
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
          criteria.should eq([ match ])
        end
      end
    end

    context "when provided criterion" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      it "returns the matching documents" do
        criteria.should eq([ match ])
      end
    end
  end

  describe "#within_box" do

    before do
      Bar.create_indexes
    end

    let!(:match) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let(:criteria) do
      Bar.within_box(location: [[ 50, 10 ], [ 60, 20 ]])
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#within_circle" do

    before do
      Bar.create_indexes
    end

    let!(:match) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let(:criteria) do
      Bar.within_circle(location: [[ 52, 13 ], 0.5 ])
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#within_polygon" do

    before do
      Bar.create_indexes
    end

    let!(:match) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let(:criteria) do
      Bar.within_polygon(
        location: [[ 50, 10 ], [ 50, 20 ], [ 60, 20 ], [ 60, 10 ]]
      )
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#within_spherical_circle" do

    before do
      Bar.create_indexes
    end

    let!(:match) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let(:criteria) do
      Bar.within_spherical_circle(location: [[ 52, 13 ], 0.5 ])
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#with_size" do

    let!(:match) do
      Band.create(genres: [ "electro", "dub" ])
    end

    let!(:non_match) do
      Band.create(genres: [ "house" ])
    end

    let(:criteria) do
      Band.with_size(genres: 2)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#with_type" do

    let!(:match) do
      Band.create(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.with_type(name: 2)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end
end
