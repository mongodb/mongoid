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

  describe "#collection" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "returns the model collection" do
      criteria.collection.should eq(Band.collection)
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
        criteria.context.should be_a(Mongoid::Contexts::Enumerable)
      end
    end

    context "when the model is not embedded" do

      let(:criteria) do
        described_class.new(Band)
      end

      it "returns the mongo context" do
        criteria.context.should be_a(Mongoid::Contexts::Mongo)
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

  pending "#create!"

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

    context "when not provided a block" do

      pending "returns an enumerator"
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

  pending "#execute_or_raise"

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

    context "when an id exists" do

      let(:criteria) do
        described_class.new(Band) do |criteria|
          criteria.selector[:id] = 1
        end
      end

      it "returns the id" do
        criteria.extract_id.should eq(1)
      end
    end

    context "when an _id exists" do

      let(:criteria) do
        described_class.new(Band) do |criteria|
          criteria.selector[:_id] = 1
        end
      end

      it "returns the _id" do
        criteria.extract_id.should eq(1)
      end
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

          it "returns the matching documents" do
            found.should eq([ band, band_two ])
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

          it "returns the matching documents" do
            found.should eq([ band, band_two ])
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

    end

    context "when using integer ids" do

    end
  end

  pending "#for_ids"
  pending "#freeze"
  pending "#from_map_or_db"

  pending "$gt"
  pending "$gte"

  pending "#in"
  pending "#any_in"

  pending "#initialize"
  pending "#includes"
  pending "#inclusions"
  pending "#inclusions="

  pending "#lt"
  pending "#lte"
  pending "#max_distance"

  pending "#merge"
  pending "#merge!"

  pending "#mod"
  pending "#ne"
  pending "#near"
  pending "#near_sphere"
  pending "#nin"
  pending "#nor"
  pending "#only"

  pending "#or"
  pending "#any_of"

  pending "#respond_to?"
  pending "#to_ary"
  pending "#to_criteria"
  pending "#to_proc"
  pending "#type"

  pending "#where"
  pending "#within_box"
  pending "#within_circle"
  pending "#within_polygon"
  pending "#within_spherical_circle"

  pending "#with_size"
  pending "#with_type"
end
