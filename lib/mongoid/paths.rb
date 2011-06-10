# encoding: utf-8
module Mongoid #:nodoc:

  # Contains logic for determining the path selectors for atomic updates.
  module Paths
    extend ActiveSupport::Concern

    included do
      cattr_accessor :__path
      attr_accessor :_index
    end

    # Get the insertion modifier for the document. Will be nil on root
    # documents, $set on embeds_one, $push on embeds_many.
    #
    # @example Get the insert operation.
    #   name.inserter
    #
    # @return [ String ] The pull or set operator.
    def _inserter
      embedded? ? (embedded_many? ? "$push" : "$set") : nil
    end

    # Return the path to this +Document+ in JSON notation, used for atomic
    # updates via $set in MongoDB.
    #
    # @example Get the path to this document.
    #   address.path
    #
    # @return [ String ] The path to the document in the database.
    def _path
      _position.sub!(/\.\d+$/, '') || _position
    end
    alias :_pull :_path

    # Returns the positional operator of this document for modification.
    #
    # @example Get the positional operator.
    #   address.position
    #
    # @return [ String ] The positional operator with indexes.
    def _position
      locator = _index ? (new_record? ? "" : ".#{_index}") : ""
      if embedded?
        "#{_parent._position}#{"." unless _parent._position.blank?}#{metadata.name.to_s}#{locator}"
      else
        ""
      end
    end

    # Get the removal modifier for the document. Will be nil on root
    # documents, $unset on embeds_one, $set on embeds_many.
    #
    # @example Get the removal operator.
    #   name.remover
    #
    # @return [ String ] The pull or unset operation.
    def _remover
      embedded? ? (_index ? "$pull" : "$unset") : nil
    end

    # Return the selector for this document to be matched exactly for use
    # with MongoDB's $ operator.
    #
    # @example Get the selector.
    #   address.selector
    #
    # @return [ String ] The exact selector for this document.
    def _selector
      (embedded? ? _parent._selector.merge("#{_path}._id" => id) : { "_id" => id }).
        merge(shard_key_selector)
    end
  end
end
