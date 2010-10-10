# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    # Insert is a persistence command responsible for taking a document that
    # has not been saved to the database and saving it.
    #
    # The underlying query resembles the following MongoDB query:
    #
    #   collection.insert(
    #     { "_id" : 1, "field" : "value" },
    #     false
    #   );
    class Insert < Command
      # Insert the new document in the database. This delegates to the standard
      # MongoDB collection's insert command.
      #
      # Example:
      #
      # <tt>Insert.persist</tt>
      #
      # Returns:
      #
      # The +Document+, whether the insert succeeded or not.
      def persist
        return @document if @validate && @document.invalid?(:create)
        @document.run_callbacks(:create) do
          @document.run_callbacks(:save) do
            if insert
              @document.new_record = false
              @document._children.each { |child| child.new_record = false }
              @document.move_changes
            end
          end
        end; @document
      end

      protected
      # Insert the document into the database.
      def insert
        if @document.embedded?
          Persistence::InsertEmbedded.new(
            @document,
            @options.merge(:validate => @validate)
          ).persist
        else
          @collection.insert(idelize(@document, @document.raw_attributes), @options)
        end
      end
      
      def idelize(document, hash)
        if hash["_id"] and document.using_object_ids? and not hash["_id"].is_a? ::BSON::ObjectId
          hash["_id"] = ::BSON::ObjectId(hash["_id"])
        end
        hash
      end
    end
  end
end
