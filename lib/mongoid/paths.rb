# encoding: utf-8
module Mongoid #:nodoc:
  module Paths #:nodoc:
    extend ActiveSupport::Concern
    included do
      cattr_accessor :_path
    end
    module InstanceMethods
      # Return the path to this +Document+ in JSON notation, used for atomic
      # updates via $set in MongoDB.
      #
      # Example:
      #
      # <tt>address.path # returns "addresses"</tt>
      def path
        self._path ||= lambda do
          embedded ? "#{_parent.path}#{"." unless _parent.path.blank?}#{@association_name}" : ""
        end.call
      end

      # Returns the positional operator of this document for modification.
      #
      # Example:
      #
      # <tt>address.position</tt>
      def position
        # TODO: Need to find the appropriate index in the array... Would be
        # nice if we had: http://jira.mongodb.org/browse/SERVER-831
        #
        # If I am embedded in an embeds_one, index is blank
        # If I am embedded in an embeds_many, index is . plus my index in the
        # array.
        index = 0
        embedded ? "#{_parent.position}#{"." unless _parent.position.blank?}#{@association_name}.#{index}" : ""
      end

      # Return the selector for this document to be matched exactly for use
      # with MongoDB's $ operator.
      #
      # Example:
      #
      # <tt>address.selector</tt>
      def selector
        embedded ? _parent.selector.merge("#{path}._id" => id) : { "_id" => id }
      end
    end
  end
end
