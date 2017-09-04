require "spec_helper"

describe "Callbacks in nested embedded document" do

  class Track

    field :price

    # same issue when using before_validation
    after_validation :set_price_when_not_exist

    private

    def set_price_when_not_exist
      if self.price.blank?
        self.price = calculate_price
      end
    end

    def calculate_price
      # some logic goes here in actual code
      100
    end
  end

  describe "when creating new document" do

    it "persistes values in embedded document callbacks" do
      band = Band.create records: [
        {
          name: "Record 1", tracks: [{name: "Track 1"}]
        }
      ]

      expect(band.records.first.tracks.first.name).to eq("Track 1")
      expect(band.records.first.tracks.first.price).to eq(100)
    end

  end

  describe "when updating document" do

    let!(:band) do
      Band.create
    end

    it "persistes values in embedded document callbacks" do
      band = Band.create

      band.update_attributes records: [
        {
          name: "Record 1", tracks: [{name: "Track 1"}]
        }
      ]

      expect(band.records.first.tracks.first.name).to eq("Track 1")
      expect(band.records.first.tracks.first.price).to eq(100)

      reloaded_from_db = Band.find_by id: band.id

      expect(reloaded_from_db.records.first.tracks.first.name).to eq("Track 1")
      expect(reloaded_from_db.records.first.tracks.first.price).to eq(100)    # FAILED: expected: 100, but got: nil
    end

  end

end
