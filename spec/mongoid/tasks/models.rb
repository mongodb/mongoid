module DatabaseSpec
  class Measurement
    include Mongoid::Document

    field :timestamp, type: Time
    field :temperature, type: Integer

    store_in collection: "measurement",
      collection_options: {
        capped: true, size: 10000
      }
  end
end
