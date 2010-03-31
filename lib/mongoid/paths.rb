# encoding: utf-8
module Mongoid #:nodoc:
  module Paths #:nodoc:
    extend ActiveSupport::Concern
    included do
      cattr_accessor :_path
      attr_accessor :_index
    end
    module InstanceMethods
      # Get the insertion modifier for the document. Will be nil on root
      # documents, $set on embeds_one, $push on embeds_many.
      #
      # Example:
      #
      # <tt>name.inserter</tt>
      def inserter
        embedded ? (_index ? "$push" : "$set") : nil
      end

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
        locator = _index ? ".#{_index}" : ""
        embedded ? "#{_parent.position}#{"." unless _parent.position.blank?}#{@association_name}#{locator}" : ""
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
