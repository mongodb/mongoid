# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    # Represents an relational one-to-many association with an object in a
    # separate collection or database, stored as an array of ids on the parent
    # document.
    class ReferencesManyAsArray < ReferencesMany

      # Append a document to this association. This will also set the appended
      # document's id on the inverse association as well.
      #
      # Example:
      #
      # <tt>person.preferences << Preference.new(:name => "VGA")</tt>
      def <<(*objects)
        load_target
        objects.flatten.each do |object|
          @parent.send(@foreign_key) << object.id
          @target << object
        end
      end

      protected
      # The default query used for retrieving the documents from the database.
      def query
        @query ||= lambda { @klass.any_in(:_id => @parent.send(@foreign_key)) }
      end
    end
  end
end
