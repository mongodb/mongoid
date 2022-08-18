module DatabaseSpec
  class Measurement
    include Mongoid::Document

    field :timestamp, type: Time
    field :temperature, type: Integer

    store_in collection: "measurement",
      collection_options: {
        time_series: {
          timeField: "timestamp",
          granularity: "hours"
        },
        expire_after: 604800
      }
  end
end
