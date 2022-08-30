module DatabaseSpec
  class Measurement
    include Mongoid::Document

    field :timestamp, type: Time
    field :temperature, type: Integer

    embeds_many :comments

    store_in collection: "measurement",
      collection_options: {
        capped: true, size: 10000
      }
  end

  class Comment
    include Mongoid::Document

    field :content, type: String

    embedded_in :measurement

    store_in collection_options: {
        capped: true, size: 10000
      }
  end

  class Note
    include Mongoid::Document

    field :text

    recursively_embeds_one

    store_in collection_options: {
      capped: true, size: 10000
    }
  end
end
