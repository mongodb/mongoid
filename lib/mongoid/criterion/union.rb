# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Union

      attr_reader :temp_collection

      # Performs a union of this criteria and the supplied criteria. This has
      # some side effects since Mongo itself does not support union queries.
      # Map/reduce can be used for some things of this nature but is not
      # optimal if Mongo is not running sharded.
      #
      # When the or is performed, the criteria will create a temporary capped
      # collection in the database that will house the ids of the documents in
      # the main collection that match either side of the criteria. No
      # duplicate ids will be in that collection.
      #
      # For each subsequent or the same process will occur if it has not for
      # the criteria that is getting unioned.
      #
      # When the criteria is iterated over or compared, then Mongoid will query
      # the database for all the records with ids in the capped collection,
      # then will drop the collection.
      def or(criteria)
        @temp_collection ||= TempCollection.new
      end
    end
  end
end
