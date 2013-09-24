require "spec_helper"

describe Mongoid::Criteria::Findable do

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
          expect(from_map).to equal(depeche)
        end
      end

      context "when providing a single id as a String" do

        let(:from_map) do
          Band.find(depeche.id.to_s)
        end

        it "returns the document from the map" do
          expect(from_map).to equal(depeche)
        end
      end

      context "when providing multiple ids" do

        let(:from_map) do
          Band.find(depeche.id, placebo.id)
        end

        it "returns the first match from the map" do
          expect(from_map.first).to equal(depeche)
        end

        it "returns the second match from the map" do
          expect(from_map.last).to equal(placebo)
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
            expect(found).to eq(band)
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
              expect(found).to be_nil
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
            expect(found).to include(band)
          end

          it "contains the second match" do
            expect(found).to include(band_two)
          end

          context "when ids are duplicates" do
            let(:found) do
              Band.find(band.id, band.id)
            end

            it "contains only the first match" do
              expect(found).to eq([band])
            end
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
              expect(found).to eq([ band ])
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
            expect(found).to include(band)
          end

          it "contains the second match" do
            expect(found).to include(band_two)
          end

          context "when ids are duplicates" do
            let(:found) do
              Band.find([ band.id, band.id ])
            end

            it "contains only the first match" do
              expect(found).to eq([band])
            end
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
              expect(found).to eq([ band ])
            end
          end
        end
      end
    end

    context "when using string ids" do

      before(:all) do
        Band.field :_id, overwrite: true, type: String
      end

      after(:all) do
        Band.field :_id, overwrite: true, type: BSON::ObjectId, default: ->{ BSON::ObjectId.new }
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
            expect(found).to eq(band)
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
              expect(found).to be_nil
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
            expect(found).to include(band)
          end

          it "contains the second match" do
            expect(found).to include(band_two)
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
              expect(found).to eq([ band ])
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
            expect(found).to include(band)
          end

          it "contains the second match" do
            expect(found).to include(band_two)
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
              expect(found).to eq([ band ])
            end
          end
        end
      end
    end

    context "when using hash ids" do

      before(:all) do
        Band.field :_id, overwrite: true, type: Hash
      end

      after(:all) do
        Band.field :_id, overwrite: true, type: BSON::ObjectId, default: ->{ BSON::ObjectId.new }
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
            expect(found).to eq(band)
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
              expect(found).to be_nil
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
            expect(found).to include(band)
          end

          it "contains the second match" do
            expect(found).to include(band_two)
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
              expect(found).to eq([ band ])
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
            expect(found).to include(band)
          end

          it "contains the second match" do
            expect(found).to include(band_two)
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
              expect(found).to eq([ band ])
            end
          end
        end
      end
    end

    context "when using integer ids" do

      before(:all) do
        Band.field :_id, overwrite: true, type: Integer
      end

      after(:all) do
        Band.field :_id, overwrite: true, type: BSON::ObjectId, default: ->{ BSON::ObjectId.new }
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
            expect(found).to eq(band)
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
              expect(found).to be_nil
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
            expect(found).to include(band)
          end

          it "contains the second match" do
            expect(found).to include(band_two)
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
              expect(found).to eq([ band ])
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
            expect(found).to include(band)
          end

          it "contains the second match" do
            expect(found).to include(band_two)
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
              expect(found).to eq([ band ])
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
            expect(found).to include(band)
          end

          it "contains the second match" do
            expect(found).to include(band_two)
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
              expect(found).to include(band)
            end

            it "contains the second match" do
              expect(found).to include(band_two)
            end

            it "returns only the matches" do
              expect(found.count).to eq(2)
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
            expect(found).to eq([band])
          end
        end
      end
    end
  end

  describe "#for_ids" do

    context "when only 1 id exists" do

      let(:id) do
        BSON::ObjectId.new
      end

      let(:criteria) do
        Band.queryable.for_ids([ id ])
      end

      it "does not turn the selector into an $in" do
        expect(criteria.selector).to eq({ "_id" => id })
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
        expect(from_map).to equal(band)
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
        expect(from_db).to_not equal(band)
      end

      it "returns the correct document" do
        expect(from_db).to eq(band)
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
        expect(from_db).to be_nil
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
          expect(from_map).to include(band)
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
          expect(from_map).to include(band, band_two)
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
          expect(from_db.first).to_not equal(band)
        end

        it "returns the correct document" do
          expect(from_db.first).to eq(band)
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
          expect(from_db.first).to_not equal(band)
        end

        it "returns the correct document" do
          expect(from_db.first).to eq(band)
        end
      end
    end
  end
end
