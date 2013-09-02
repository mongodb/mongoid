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

  describe "#asc" do

    let(:person) do
      Person.create
    end

    context "when the documents are embedded" do

      let!(:hobrecht) do
        person.addresses.create(street: "hobrecht", name: "hobrecht")
      end

      let!(:friedel) do
        person.addresses.create(street: "friedel", name: "friedel")
      end

      let!(:pfluger) do
        person.addresses.create(street: "pfluger", name: "pfluger")
      end

      let(:criteria) do
        person.addresses.asc(:name)
      end

      it "returns the sorted documents" do
        criteria.should eq([ friedel, hobrecht, pfluger ])
      end
    end
  end

  describe "#batch_size" do

    let(:person) do
      Person.create
    end

    let(:criteria) do
      Person.batch_size(1000)
    end

    it "adds the batch size option" do
      criteria.options[:batch_size].should eq(1000)
    end

    it "returns the correct documents" do
      criteria.should eq([ person ])
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
          band.should be_new_record
        end

        it "sets the criteria attributes" do
          band.name.should eq("Depeche Mode")
        end

        it "sets the attributes passed to build" do
          band.genres.should eq([ "electro" ])
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
    end
  end

  describe "#cache" do

    let!(:person) do
      Person.create
    end

    context "when no eager loading is involved" do

      let(:criteria) do
        Person.all.cache
      end

      before do
        criteria.each {}
      end

      it "does not hit the database after first iteration" do
        criteria.context.query.should_receive(:each).never
        criteria.each do |doc|
          doc.should eq(person)
        end
      end
    end

    context "when the criteria is eager loading" do

      let(:criteria) do
        Person.includes(:posts).cache
      end

      before do
        criteria.each {}
      end

      it "does not hit the database after first iteration" do
        criteria.context.query.should_receive(:each).never
        criteria.each do |doc|
          doc.should eq(person)
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

    context "when provided a block" do
      context "when provided valid attributes & using block" do
        let(:band) do
          criteria.create do |c|
            c.genres = [ "electro" ]
          end
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

  describe "#delete" do

    let(:depeche) do
      Band.create(name: "Depeche Mode")
    end

    let(:tool) do
      Band.create(name: "Tool")
    end

    context "when no selector is provided" do

      before do
        Band.all.delete
      end

      it "deletes all the documents from the database" do
        Band.count.should eq(0)
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

  describe "#embedded?" do

    let(:person) do
      Person.new
    end

    context "when the criteria is embedded" do

      let(:criteria) do
        person.addresses.where(street: "hobrecht")
      end

      it "returns true" do
        criteria.should be_embedded
      end
    end

    context "when the criteria is not embedded" do

      let(:criteria) do
        Person.where(active: true)
      end

      it "returns false" do
        criteria.should_not be_embedded
      end
    end
  end

  describe "#empty?" do

    context "when matching documents exist" do

      let!(:match) do
        Band.create(name: "Depeche Mode")
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
        Band.create(name: "New Order")
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

  describe "#explain" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "returns the criteria explain path" do
      criteria.explain["cursor"].should eq("BasicCursor")
    end
  end

  describe "#extract_id" do

    let(:id) do
      Moped::BSON::ObjectId.new
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

    context "when finding by a document" do

      let(:band) do
        Band.create(name: "Tool")
      end

      let!(:record) do
        band.records.create(name: "Undertow")
      end

      context "when the document is the root" do

        let(:found) do
          Band.find(band)
        end

        it "returns the matching document" do
          expect(found).to eq(band)
        end
      end

      context "when the document is the proxy" do

        let(:found) do
          Band.find(band.records.first.band)
        end

        it "returns the matching document" do
          expect(found).to eq(band)
        end
      end
    end

    context "when the identity map is enabled" do

      before(:all) do
        Mongoid.identity_map_enabled = true
      end

      after(:all) do
        Mongoid.identity_map_enabled = false
      end

      let!(:depeche) do
        Band.create(name: "Depeche Mode")
      end

      let!(:placebo) do
        Band.create(name: "Placebo")
      end

      context "when a parent and a child are in the identity map" do

        let!(:canvas) do
          Canvas.create
        end

        let!(:browser) do
          Browser.create
        end

        context "when fetching a child class by a parent id" do

          it "raises a not found error" do
            expect {
              Browser.find(canvas.id)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end

      context "when providing a single id" do

        let(:from_map) do
          Band.find(depeche.id)
        end

        it "returns the document from the map" do
          from_map.should equal(depeche)
        end
      end

      context "when providing a single id as a String" do

        let(:from_map) do
          Band.find(depeche.id.to_s)
        end

        it "returns the document from the map" do
          from_map.should equal(depeche)
        end
      end

      context "when providing multiple ids" do

        let(:from_map) do
          Band.find(depeche.id, placebo.id)
        end

        it "returns the first match from the map" do
          from_map.first.should equal(depeche)
        end

        it "returns the second match from the map" do
          from_map.last.should equal(placebo)
        end
      end
    end

    context "when using object ids" do

      let!(:band) do
        Band.create
      end

      context "when a parent and a child are in the identity map" do

        let!(:canvas) do
          Canvas.create
        end

        let!(:browser) do
          Browser.create
        end

        context "when fetching a child class by a parent id" do

          it "raises a not found error" do
            expect {
              Browser.find(canvas.id)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
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
              Band.find(Moped::BSON::ObjectId.new)
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
              Band.find(Moped::BSON::ObjectId.new)
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

          context "when ids are duplicates" do
            let(:found) do
              Band.find(band.id, band.id)
            end

            it "contains only the first match" do
              found.should eq([band])
            end
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(band.id, Moped::BSON::ObjectId.new)
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
              Band.find(band.id, Moped::BSON::ObjectId.new)
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

          context "when ids are duplicates" do
            let(:found) do
              Band.find([ band.id, band.id ])
            end

            it "contains only the first match" do
              found.should eq([band])
            end
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find([ band.id, Moped::BSON::ObjectId.new ])
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
              Band.find([ band.id, Moped::BSON::ObjectId.new ])
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
        Band.field :_id, type: Moped::BSON::ObjectId, default: ->{ Moped::BSON::ObjectId.new }
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

    context "when using hash ids" do

      before(:all) do
        Band.field :_id, type: Hash
      end

      after(:all) do
        Band.field :_id, type: Moped::BSON::ObjectId, default: ->{ Moped::BSON::ObjectId.new }
      end

      let!(:band) do
        Band.create do |band|
          band.id = {"new-order" => true, "Depeche Mode" => false}
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
              Band.find({"new-order" => false, "Faith no More" => true})
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
              Band.find({"new-order" => false, "Faith no More" => true})
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
            band.id = {"Radiohead" => false, "Nirvana"=> true}
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
              Band.find(band.id, {"Radiohead" => true, "Nirvana"=> false})
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
              Band.find(band.id, {"Radiohead" => true, "Nirvana"=> false})
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
            band.id = {"Radiohead" => false, "Nirvana"=> true}
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
              Band.find([ band.id, {"Radiohead" => true, "Nirvana"=> false} ])
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
              Band.find([ band.id, {"Radiohead" => true, "Nirvana"=> false} ])
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
        Band.field :_id, type: Moped::BSON::ObjectId, default: ->{ Moped::BSON::ObjectId.new }
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

    context "when using string and object ids" do

      let!(:band) do
        Band.create
      end

      context "when providing multiple ids" do

        context "when ids are duplicates" do

          let(:found) do
            Band.find([ band.id.to_s, band.id ])
          end

          it "contains only the first match" do
            found.should eq([band])
          end
        end
      end
    end
  end

  describe "#find_and_modify" do

    let!(:depeche) do
      Band.create(name: "Depeche Mode")
    end

    let!(:tool) do
      Band.create(name: "Tool")
    end

    context "when the selector matches" do

      context "when the identity map is enabled" do

        before(:all) do
          Mongoid.identity_map_enabled = true
        end

        after(:all) do
          Mongoid.identity_map_enabled = false
        end

        context "when returning the updated document" do

          let(:criteria) do
            Band.where(name: "Depeche Mode")
          end

          let(:result) do
            criteria.find_and_modify({ "$inc" => { likes: 1 }}, new: true)
          end

          it "returns the first matching document" do
            result.should eq(depeche)
          end

          it "updates the document in the identity map" do
            Mongoid::IdentityMap.get(Band, result.id).likes.should eq(1)
          end
        end

        context "when not returning the updated document" do

          let(:criteria) do
            Band.where(name: "Depeche Mode")
          end

          let!(:result) do
            criteria.find_and_modify("$inc" => { likes: 1 })
          end

          before do
            depeche.reload
          end

          it "returns the first matching document" do
            result.should eq(depeche)
          end

          it "updates the document in the identity map" do
            Mongoid::IdentityMap.get(Band, depeche.id).likes.should eq(1)
          end
        end
      end

      context "when not providing options" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let!(:result) do
          criteria.find_and_modify("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          result.should eq(depeche)
        end

        it "updates the document in the database" do
          depeche.reload.likes.should eq(1)
        end
      end

      context "when sorting" do

        let(:criteria) do
          Band.desc(:name)
        end

        let!(:result) do
          criteria.find_and_modify("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          result.should eq(tool)
        end

        it "updates the document in the database" do
          tool.reload.likes.should eq(1)
        end
      end

      context "when limiting fields" do

        let(:criteria) do
          Band.only(:_id)
        end

        let!(:result) do
          criteria.find_and_modify("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          result.should eq(depeche)
        end

        it "limits the returned fields" do
          result.name.should be_nil
        end

        it "updates the document in the database" do
          depeche.reload.likes.should eq(1)
        end
      end

      context "when returning new" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let!(:result) do
          criteria.find_and_modify({ "$inc" => { likes: 1 }}, new: true)
        end

        it "returns the first matching document" do
          result.should eq(depeche)
        end

        it "returns the updated document" do
          result.likes.should eq(1)
        end
      end

      context "when removing" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let!(:result) do
          criteria.find_and_modify({}, remove: true)
        end

        it "returns the first matching document" do
          result.should eq(depeche)
        end

        it "deletes the document from the database" do
          expect {
            depeche.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end
    end

    context "when the selector does not match" do

      let(:criteria) do
        Band.where(name: "Placebo")
      end

      let(:result) do
        criteria.find_and_modify("$inc" => { likes: 1 })
      end

      it "returns nil" do
        result.should be_nil
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
        found.should eq(band)
      end
    end

    context "when the document is not found" do

      context "when attributes are provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_initialize(origin: "Essex")
        end

        it "returns a new document" do
          document.name.should eq("Tool")
        end

        it "returns a non persisted document" do
          document.should_not be_persisted
        end

        it "sets the additional attributes" do
          document.origin.should eq("Essex")
        end
      end

      context "when attributes are not provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_initialize
        end

        it "returns a new document" do
          document.name.should eq("Tool")
        end

        it "returns a non persisted document" do
          document.should_not be_persisted
        end
      end

      context "when a block is provided" do

        let(:document) do
          Band.where(name: "Tool").first_or_initialize do |doc|
            doc.active = false
          end
        end

        it "returns a new document" do
          document.name.should eq("Tool")
        end

        it "returns a non persisted document" do
          document.should_not be_persisted
        end

        it "yields to the block" do
          document.active.should be_false
        end
      end

      context "when the criteria is complex" do

        context "when the document is not found" do

          let(:document) do
            Band.in(name: [ "New Order" ]).first_or_initialize(active: false)
          end

          it "returns a new document" do
            document.active.should be_false
          end

          it "returns a non persisted document" do
            document.should_not be_persisted
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

  describe "#for_ids" do

    context "when only 1 id exists" do

      let(:id) do
        Moped::BSON::ObjectId.new
      end

      let(:criteria) do
        Band.queryable.for_ids([ id ])
      end

      it "does not turn the selector into an $in" do
        criteria.selector.should eq({ "_id" => id })
      end
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

    context "when the selector is cleared in the identity map" do

      let!(:band) do
        Band.create(name: "Depeche Mode")
      end

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      before do
        Mongoid::IdentityMap.clear
        Mongoid::IdentityMap.clear_many(Band, { "name" => "Depeche Mode" })
      end

      let(:from_db) do
        criteria.from_map_or_db
      end

      it "returns nil" do
        from_db.should be_nil
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

  describe "#geo_near" do

    before do
      Bar.create_indexes
    end

    let!(:match) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let(:criteria) do
      Bar.geo_near([ 52, 13 ]).max_distance(10).spherical
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#gt" do

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

  describe "#gte" do

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

      context "when querying on a normal field" do

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

      context "when querying on a foreign key" do

        let(:id) do
          Moped::BSON::ObjectId.new
        end

        let!(:match_one) do
          Person.create(preference_ids: [ id ])
        end

        context "when providing valid ids" do

          let(:criteria) do
            Person.send(method, preference_ids: [ id ])
          end

          it "returns the matching documents" do
            criteria.should eq([ match_one ])
          end
        end

        context "when providing empty strings" do

          let(:criteria) do
            Person.send(method, preference_ids: [ id, "" ])
          end

          it "returns the matching documents" do
            criteria.should eq([ match_one ])
          end
        end

        context "when providing nils" do

          context "when the relation is a many to many" do

            let(:criteria) do
              Person.send(method, preference_ids: [ id, nil ])
            end

            it "returns the matching documents" do
              criteria.should eq([ match_one ])
            end
          end

          context "when the relation is a one to one" do

            let!(:game) do
              Game.create
            end

            let(:criteria) do
              Game.send(method, person_id: [ nil ])
            end

            it "returns the matching documents" do
              criteria.should eq([ game ])
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

    context "when providing a name that is not a relation" do

      it "raises an error" do
        expect {
          Person.includes(:members)
        }.to raise_error(Mongoid::Errors::InvalidIncludes)
      end
    end

    context "when providing a hash" do

      it "raises an error" do
        expect {
          Person.includes(preferences: :members)
        }.to raise_error(Mongoid::Errors::InvalidIncludes)
      end
    end

    context "when the models are inherited" do

      before(:all) do
        class A
          include Mongoid::Document
        end

        class B < A
          belongs_to :c
        end

        class C
          include Mongoid::Document
          has_one :b
        end
      end

      after(:all) do
        Object.send(:remove_const, :A)
        Object.send(:remove_const, :B)
        Object.send(:remove_const, :C)
      end

      context "when the includes is on the subclass" do

        let!(:c_one) do
          C.create
        end

        let!(:c_two) do
          C.create
        end

        let!(:b) do
          B.create(c: c_two)
        end

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:results) do
          C.includes(:b).entries.detect do |c|
            c.id == c_two.id
          end
        end

        let(:from_map) do
          Mongoid::IdentityMap[B.collection_name][b.id]
        end

        it "returns the correct documents" do
          results.should eq(c_two)
        end

        it "inserts the first document into the identity map" do
          from_map.should eq(b)
        end

        it "retrieves the document from the identity map" do
          results.b.should equal(from_map)
        end
      end
    end

    context "when the models are inherited from another one model" do

      context "when the relation is a has_one" do

        before(:all) do
          class A
            include Mongoid::Document
          end

          class B < A
            belongs_to :d
          end

          class C < A
            belongs_to :d
          end

          class D
            include Mongoid::Document
            has_one :b
            has_one :c
          end
        end

        after(:all) do
          Object.send(:remove_const, :A)
          Object.send(:remove_const, :B)
          Object.send(:remove_const, :C)
          Object.send(:remove_const, :D)
        end

        context "when the includes is on the several relations" do

          let!(:d_one) do
            D.create
          end

          let!(:d_two) do
            D.create
          end

          let!(:b) do
            B.create(d: d_two)
          end

          let!(:c) do
            C.create(d: d_two)
          end

          before do
            Mongoid::IdentityMap.clear
          end

          let!(:results) do
            D.includes(:b, :c).entries.detect do |d|
              d.id == d_two.id
            end
          end

          let(:from_map_b) do
            Mongoid::IdentityMap[B.collection_name][b.id]
          end

          let(:from_map_c) do
            Mongoid::IdentityMap[C.collection_name][c.id]
          end

          it "returns the correct documents" do
            results.should eq(d_two)
          end

          it "inserts the b document into the identity map" do
            from_map_b.should eq(b)
          end

          it "inserts the c document into the identity map" do
            from_map_c.should eq(c)
          end

          it "retrieves the b document from the identity map" do
            results.b.should equal(from_map_b)
          end

          it "retrieves the c document from the identity map" do
            results.c.should equal(from_map_c)
          end
        end
      end

      context "when the relation is a has_many" do

        before(:all) do
          class A
            include Mongoid::Document
          end

          class B < A
            belongs_to :d
          end

          class C < A
            belongs_to :d
          end

          class D
            include Mongoid::Document
            has_many :b
            has_many :c
          end
        end

        after(:all) do
          Object.send(:remove_const, :A)
          Object.send(:remove_const, :B)
          Object.send(:remove_const, :C)
          Object.send(:remove_const, :D)
        end

        context "when the includes is on the several relations" do

          let!(:d_one) do
            D.create
          end

          let!(:d_two) do
            D.create
          end

          let!(:bs) do
            2.times.map { B.create(d: d_two) }
          end

          let!(:cs) do
            2.times.map { C.create(d: d_two) }
          end

          before do
            Mongoid::IdentityMap.clear
          end

          let!(:results) do
            D.includes(:b, :c).entries.detect do |d|
              d.id == d_two.id
            end
          end

          let(:from_map_bs) do
            bs.map { |b| Mongoid::IdentityMap[B.collection_name][b.id] }
          end

          let(:from_map_cs) do
            cs.map { |c| Mongoid::IdentityMap[C.collection_name][c.id] }
          end

          it "returns the correct documents" do
            results.should eq(d_two)
          end

          it "inserts the b documents into the identity map" do
            from_map_bs.should eq(bs)
          end

          it "inserts the c documents into the identity map" do
            from_map_cs.should eq(cs)
          end

          it "retrieves the b documents from the identity map" do
            results.b.should match_array(from_map_bs)
          end

          it "retrieves the c documents from the identity map" do
            results.c.should match_array(from_map_cs)
          end
        end
      end
    end

    context "when including the same metadata multiple times" do

      let(:criteria) do
        Person.all.includes(:posts, :posts).includes(:posts)
      end

      let(:metadata) do
        Person.reflect_on_association(:posts)
      end

      it "does not duplicate the metadata in the inclusions" do
        criteria.inclusions.should eq([ metadata ])
      end
    end

    context "when mapping the results more than once" do

      before do
        Mongoid::IdentityMap.clear
      end

      let!(:post) do
        person.posts.create(title: "one")
      end

      let(:criteria) do
        Post.includes(:person)
      end

      let!(:results) do
        criteria.map { |doc| doc }
        criteria.map { |doc| doc }
      end

      it "returns the proper results" do
        results.first.title.should eq("one")
      end
    end

    context "when including a belongs to relation" do

      context "when the criteria is from an embedded relation" do

        let(:peep) do
          Person.create
        end

        let!(:address_one) do
          peep.addresses.create(street: "rosenthaler")
        end

        let!(:address_two) do
          peep.addresses.create(street: "weinmeister")
        end

        let!(:depeche) do
          Band.create!(name: "Depeche Mode")
        end

        let!(:tool) do
          Band.create!(name: "Tool")
        end

        before do
          address_one.band = depeche
          address_two.band = tool
          address_one.save
          address_two.save
        end

        context "when calling first" do

          before do
            Mongoid::IdentityMap.clear
          end

          let(:criteria) do
            peep.reload.addresses.includes(:band)
          end

          let(:context) do
            criteria.context
          end

          before do
            context.should_receive(:eager_load_one).with(address_one).once.and_call_original
          end

          let!(:document) do
            criteria.first
          end

          let(:eager_loaded) do
            Mongoid::IdentityMap[Band.collection_name]
          end

          it "eager loads the first document" do
            eager_loaded[depeche.id].should eq(depeche)
          end

          it "does not eager load the last document" do
            eager_loaded[tool.id].should be_nil
          end

          it "returns the document" do
            document.should eq(address_one)
          end
        end

        context "when calling last" do

          before do
            Mongoid::IdentityMap.clear
          end

          let(:criteria) do
            peep.reload.addresses.includes(:band)
          end

          let(:context) do
            criteria.context
          end

          before do
            context.should_receive(:eager_load_one).with(address_two).once.and_call_original
          end

          let!(:document) do
            criteria.last
          end

          let(:eager_loaded) do
            Mongoid::IdentityMap[Band.collection_name]
          end

          it "does not eager load the first document" do
            eager_loaded[depeche.id].should be_nil
          end

          it "eager loads the last document" do
            eager_loaded[tool.id].should eq(tool)
          end

          it "returns the document" do
            document.should eq(address_two)
          end
        end

        context "when iterating all documents" do

          before do
            Mongoid::IdentityMap.clear
          end

          let(:criteria) do
            peep.reload.addresses.includes(:band)
          end

          let(:context) do
            criteria.context
          end

          before do
            context.
              should_receive(:eager_load).
              with([ address_one, address_two ]).
              once.
              and_call_original
          end

          let!(:documents) do
            criteria.to_a
          end

          let(:eager_loaded) do
            Mongoid::IdentityMap[Band.collection_name]
          end

          it "eager loads the first document" do
            eager_loaded[depeche.id].should eq(depeche)
          end

          it "eager loads the last document" do
            eager_loaded[tool.id].should eq(tool)
          end

          it "returns the documents" do
            documents.should eq([ address_one, address_two ])
          end
        end
      end

      context "when the criteria is from the root" do

        let!(:person_two) do
          Person.create
        end

        let!(:post_one) do
          person.posts.create(title: "one")
        end

        let!(:post_two) do
          person_two.posts.create(title: "two")
        end

        before do
          Mongoid::IdentityMap.clear
        end

        context "when calling first" do

          let!(:criteria) do
            Post.includes(:person)
          end

          let!(:context) do
            criteria.context
          end

          before do
            context.should_receive(:eager_load_one).with(post_one).once.and_call_original
          end

          let!(:document) do
            criteria.first
          end

          it "eager loads for the first document" do
            Mongoid::IdentityMap[Person.collection_name][person.id].should eq(person)
          end

          it "does not eager loads for the last document" do
            Mongoid::IdentityMap[Person.collection_name][person_two.id].should be_nil
          end

          it "returns the first document" do
            document.should eq(post_one)
          end
        end

        context "when calling last" do

          let!(:criteria) do
            Post.includes(:person)
          end

          let!(:context) do
            criteria.context
          end

          before do
            context.should_receive(:eager_load_one).with(post_two).once.and_call_original
          end

          let!(:document) do
            criteria.last
          end

          it "eager loads for the first document" do
            Mongoid::IdentityMap[Person.collection_name][person_two.id].should eq(person_two)
          end

          it "does not eager loads for the last document" do
            Mongoid::IdentityMap[Person.collection_name][person.id].should be_nil
          end

          it "returns the last document" do
            document.should eq(post_two)
          end
        end
      end
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
          Person.all
        end

        let!(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load).with([ person ]).once.and_call_original
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          documents.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end

        context "when executing the query twice" do

          let!(:new_criteria) do
            Person.where(id: person.id)
          end

          let!(:new_context) do
            new_criteria.context
          end

          before do
            new_context.should_receive(:eager_load_one).with(person).once.and_call_original
          end

          let!(:from_db) do
            new_criteria.first
          end

          let(:mapped) do
            Mongoid::IdentityMap[Post.collection_name][{"person_id" => person.id}]
          end

          it "does not duplicate documents in the relation" do
            person.posts.size.should eq(2)
          end

          it "does not duplicate documents in the map" do
            mapped.size.should eq(2)
          end
        end
      end

      context "when calling first on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let(:criteria) do
          Person.all
        end

        let!(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load_one).with(person).once.and_call_original
        end

        let!(:from_db) do
          criteria.first
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

        let(:criteria) do
          Person.all
        end

        let!(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load_one).with(person).once.and_call_original
        end

        let!(:from_db) do
          criteria.last
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
          Person.asc(:_id).limit(1)
        end

        let(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load).with([ person ]).once.and_call_original
        end

        let!(:documents) do
          criteria.entries
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
          Person.includes(:preferences)
        end

        let(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load).with([ person ]).once.and_call_original
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          documents.should eq([ person ])
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

        let!(:criteria) do
          Person.includes(:preferences)
        end

        let(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load_one).with(person).once.and_call_original
        end

        let!(:from_db) do
          criteria.first
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

        let!(:criteria) do
          Person.includes(:preferences)
        end

        let(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load_one).with(person).once.and_call_original
        end

        let!(:from_db) do
          criteria.last
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
          Person.includes(:preferences).asc(:_id).limit(1)
        end

        let(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load).with([ person ]).once.and_call_original
        end

        let!(:documents) do
          criteria.entries
        end

        let(:preference_map) do
          Mongoid::IdentityMap[Preference.collection_name]
        end

        it "returns the correct documents" do
          documents.should eq([ person ])
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
          Person.includes(:posts)
        end

        let(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load).with([ person ]).once.and_call_original
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          documents.should eq([ person ])
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

        let!(:criteria) do
          Person.includes(:posts)
        end

        let(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load_one).with(person).once.and_call_original
        end

        let!(:from_db) do
          criteria.first
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

        context "when subsequently getting all documents" do

          before do
            context.should_receive(:eager_load).with([ person ]).once.and_call_original
          end

          let!(:documents) do
            criteria.entries
          end

          it "returns the correct documents" do
            documents.should eq([ person ])
          end
        end
      end

      context "when calling last on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:posts)
        end

        let(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load_one).with(person).once.and_call_original
        end

        let!(:from_db) do
          criteria.last
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

        context "when subsequently getting all documents" do

          before do
            context.should_receive(:eager_load).with([ person ]).once.and_call_original
          end

          let!(:documents) do
            criteria.entries
          end

          it "returns the correct documents" do
            documents.should eq([ person ])
          end
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
          Person.includes(:posts).asc(:_id).limit(1)
        end

        let(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load).with([ person ]).once.and_call_original
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          documents.should eq([ person ])
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
          Person.includes(:game)
        end

        let(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load).with([ person ]).once.and_call_original
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          documents.should eq([ person ])
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
          Person.where(id: person.id).includes(:game).asc(:_id).limit(1)
        end

        let(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load).with([ person ]).once.and_call_original
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          documents.should eq([ person ])
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
          Game.includes(:person)
        end

        let(:context) do
          criteria.context
        end

        before do
          context.
            should_receive(:eager_load).
            with([ game_one, game_two ]).
            once.
            and_call_original
        end

        let!(:documents) do
          criteria.entries
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
          Game.where(id: game_one.id).includes(:person).asc(:_id).limit(1)
        end

        let(:context) do
          criteria.context
        end

        before do
          context.should_receive(:eager_load).with([ game_one ]).once.and_call_original
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          documents.should eq([ game_one ])
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
        Person.includes(:posts, :game)
      end

      let(:context) do
        criteria.context
      end

      before do
        context.should_receive(:eager_load).with([ person ]).once.and_call_original
      end

      let!(:documents) do
        criteria.entries
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

    context "when merging with another criteria" do

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

    context "when merging with a hash" do

      let(:mergeable) do
        { klass: Band, includes: [ :records ] }
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
      Band.create(name: "Depeche Mode", likes: 3, views: 10)
    end

    context "when not using inheritance" do

      context "when passing splat args" do

        let(:criteria) do
          Band.only(:_id)
        end

        it "limits the returned fields" do
          criteria.first.name.should be_nil
        end

        it "does not add _type to the fields" do
          criteria.options[:fields]["_type"].should be_nil
        end
      end

      context "when passing an array" do

        let(:criteria) do
          Band.only([ :name, :likes ])
        end

        it "includes the limited fields" do
          criteria.first.name.should_not be_nil
        end

        it "excludes the non included fields" do
          criteria.first.active.should be_nil
        end

        it "does not add _type to the fields" do
          criteria.options[:fields]["_type"].should be_nil
        end
      end

      context "when instantiating a class of another type inside the iteration" do

        let(:criteria) do
          Band.only(:name)
        end

        it "only limits the fields on the correct model" do
          criteria.each do |band|
            Person.new.age.should eq(100)
          end
        end
      end

      context "when instantiating a document not in the result set" do

        let(:criteria) do
          Band.only(:name)
        end

        it "only limits the fields on the correct criteria" do
          criteria.each do |band|
            Band.new.active.should be_true
          end
        end
      end

      context "when nesting a criteria within a criteria" do

        let(:criteria) do
          Band.only(:name)
        end

        it "only limits the fields on the correct criteria" do
          criteria.each do |band|
            Band.all.each do |b|
              b.active.should be_true
            end
          end
        end
      end
    end

    context "when using inheritance" do

      let(:criteria) do
        Doctor.only(:_id)
      end

      it "adds _type to the fields" do
        criteria.options[:fields]["_type"].should eq(1)
      end
    end

    context "when limiting to embedded documents" do

      context "when the embedded documents are aliased" do

        let(:criteria) do
          Person.only(:phones)
        end

        it "properly uses the database field name" do
          criteria.options.should eq(fields: { "mobile_phones" => 1 })
        end
      end
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

      context "when sending a normal $or criterion" do

        let(:criteria) do
          Band.send(method, { name: "Depeche Mode" }, { name: "New Order" })
        end

        it "returns the matching documents" do
          criteria.should eq([ match ])
        end
      end

      context "when matching against an id or other parameter" do

        let(:criteria) do
          Band.send(method, { id: match.id }, { name: "New Order" })
        end

        it "returns the matching documents" do
          criteria.should eq([ match ])
        end
      end
    end
  end

  describe "#pluck" do

    let!(:depeche) do
      Band.create(name: "Depeche Mode", likes: 3)
    end

    let!(:tool) do
      Band.create(name: "Tool", likes: 3)
    end

    let!(:photek) do
      Band.create(name: "Photek", likes: 1)
    end

    context "when the criteria matches" do

      context "when there are no duplicate values" do

        let(:criteria) do
          Band.where(:name.exists => true)
        end

        let!(:plucked) do
          criteria.pluck(:name)
        end

        it "returns the values" do
          plucked.should eq([ "Depeche Mode", "Tool", "Photek" ])
        end

        context "when subsequently executing the criteria without a pluck" do

          it "does not limit the fields" do
            expect(criteria.first.likes).to eq(3)
          end
        end
      end

      context "when there are duplicate values" do

        let(:plucked) do
          Band.where(:name.exists => true).pluck(:likes)
        end

        it "returns the duplicates" do
          plucked.should eq([ 3, 3, 1 ])
        end
      end
    end

    context "when the criteria does not match" do

      let(:plucked) do
        Band.where(name: "New Order").pluck(:_id)
      end

      it "returns an empty array" do
        plucked.should be_empty
      end
    end

    context "when plucking an aliased field" do

      let(:plucked) do
        Band.all.pluck(:id)
      end

      it "returns the field values" do
        plucked.should eq([ depeche.id, tool.id, photek.id ])
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

  describe "#sort" do

    let!(:depeche) do
      Band.create(name: "Depeche Mode", likes: 1000)
    end

    let!(:tool) do
      Band.create(name: "Tool", likes: 500)
    end

    let(:sorted) do
      Band.all.sort do |a, b|
        b.name <=> a.name
      end
    end

    it "sorts the results in memory" do
      sorted.should eq([ tool, depeche ])
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

  describe "#extras with a hint" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode").extras(:hint => {:bad_hint => 1})
    end

    it "executes the criteria while properly giving the hint to Mongo" do
      expect { criteria.to_ary }.to raise_error(Moped::Errors::QueryFailure,  %r{failed with error 10113: "bad hint"})
    end
  end

  describe "#hint" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode").hint(bad_hint: 1)
    end

    it "executes the criteria while properly giving the hint to Mongo" do
      expect { criteria.to_ary }.to raise_error(Moped::Errors::QueryFailure,  %r{failed with error 10113: "bad hint"})
    end
  end

  describe "#max_scan" do
    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let!(:band2) do
      Band.create(name: "Tool")
    end

    let(:criteria) do
      Band.where({}).max_scan(1)
    end

    it "executes the criteria while properly giving the max scan to Mongo" do
      criteria.to_ary.should eq [band]
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

      context "when the criteria is standard" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        it "returns the matching documents" do
          criteria.should eq([ match ])
        end
      end

      context "when the criteria is an exact fk array match" do

        let(:id_one) do
          Moped::BSON::ObjectId.new
        end

        let(:id_two) do
          Moped::BSON::ObjectId.new
        end

        let(:criteria) do
          Account.where(agent_ids: [ id_one, id_two ])
        end

        it "does not wrap the array in another array" do
          criteria.selector.should eq({ "agent_ids" => [ id_one, id_two ]})
        end
      end
    end
  end

  describe "#for_js" do

    let!(:match) do
      Band.create(name: "Depeche Mode")
    end

    context "when the code has no scope" do

      let(:criteria) do
        Band.for_js("this.name == 'Depeche Mode'")
      end

      it "returns the matching documents" do
        criteria.should eq([ match ])
      end
    end

    context "when the code has scope" do

      let(:criteria) do
        Band.for_js("this.name == param", param: "Depeche Mode")
      end

      it "returns the matching documents" do
        criteria.should eq([ match ])
      end
    end
  end

  describe "#method_missing" do

    let(:criteria) do
      Person.all
    end

    context "when the method exists on the class" do

      before do
        Person.should_receive(:minor).and_call_original
      end

      it "calls the method on the class" do
        expect(criteria.minor).to be_empty
      end
    end

    context "when the method exists on the criteria" do

      before do
        criteria.should_receive(:to_criteria).and_call_original
      end

      it "calls the method on the criteria" do
        expect(criteria.to_criteria).to eq(criteria)
      end
    end

    context "when the method exists on array" do

      before do
        criteria.should_receive(:entries).and_call_original
      end

      it "calls the method on the criteria" do
        expect(criteria.at(0)).to be_nil
      end
    end

    context "when the method does not exist" do

      before do
        criteria.should_receive(:entries).never
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
      Band.create(name: "New Order")
    end

    let!(:band_two) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    it "passes the block through method_missing" do
      criteria.uniq(&:name).should eq([ band_one ])
    end
  end

  describe "#with" do

    let!(:criteria) do
      Band.where(name: "Depeche Mode").with(collection: "artists")
    end

    after do
      Band.persistence_options.clear
    end

    it "retains the criteria selection" do
      criteria.selector.should eq("name" => "Depeche Mode")
    end

    it "sets the persistence options" do
      Band.persistence_options.should eq(collection: "artists")
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

  describe "#without" do

    context "when omitting to embedded documents" do

      context "when the embedded documents are aliased" do

        let(:criteria) do
          Person.without(:phones)
        end

        it "properly uses the database field name" do
          criteria.options.should eq(fields: { "mobile_phones" => 0 })
        end
      end
    end
  end
end
