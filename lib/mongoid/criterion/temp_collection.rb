# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    class TempCollection

      attr_reader :collection

      # Create a new temporary capped collection with a uuid as it's name. Used
      # for storing document ids when performing or criteria.
      def initialize
        id = Mongo::ObjectID.new.to_s
        db = Mongoid.database
        size = Mongoid.temp_collection_size
        @collection = db.create_collection(id, :capped => true, :size => size)
      end
    end
  end
end
