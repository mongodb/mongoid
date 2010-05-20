# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    # Represents an relational one-to-many association with an object in a
    # separate collection or database, stored as an array of ids on the parent
    # document.
    class ReferencesManyAsArray < ReferencesMany

      protected
      # The default query used for retrieving the documents from the database.
      def query
        @query ||= lambda { @klass.any_in(:_id => @parent.send(@foreign_key)) }
      end
    end
  end
end
