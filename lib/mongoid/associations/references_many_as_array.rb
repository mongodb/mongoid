# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    # Represents an relational one-to-many association with an object in a
    # separate collection or database, stored as an array of ids on the parent
    # document.
    class ReferencesManyAsArray < Proxy

      def each(&block)
        [].each(&block)
      end

      # Initializing a related association only requires looking up the objects
      # by their ids.
      #
      # Options:
      #
      # document: The +Document+ that contains the relationship.
      # options: The association +Options+.
      def initialize(document, options, target = nil)
        setup(document, options)
        @target = target || query.call
      end

      protected
      # The default query used for retrieving the documents from the database.
      def query
        @query ||= lambda { @klass.any_in(:_id => @parent.send(@foreign_key)) }
      end

      class << self
        # Preferred method for creating the new +ReferencesManyAsArray+
        # association.
        #
        # Options:
        #
        # document: The +Document+ that contains the relationship.
        # options: The association +Options+.
        def instantiate(document, options, target = nil)
          new(document, options, target)
        end
      end
    end
  end
end
