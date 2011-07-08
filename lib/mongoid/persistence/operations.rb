# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:

    # Persistence operations include this module to get basic functionality
    # on initialization.
    module Operations

      attr_reader :document, :selector

      # Get the collection we should be persisting to.
      #
      # @example Get the collection.
      #   operation.collection
      #
      # @return [ Collection ] The collection to persist to.
      #
      # @since 2.1.0
      def collection
        @collection ||= document._root.collection
      end

      # Instantiate the new persistence operation.
      #
      # @example Create the operation.
      #   Operation.new(document, { :safe => true }, { "field" => "value" })
      #
      # @param [ Document ] document The document to persist.
      # @param [ Hash ] options The persistence options.
      #
      # @since 2.1.0
      def initialize(document, options = {})
        @document, @options = document, options
      end

      # Should the parent document (in the case of embedded persistence) be
      # notified of the child deletion. This is used when calling delete from
      # the associations themselves.
      #
      # @example Should the parent be notified?
      #   operation.notifying_parent?
      #
      # @return [ true, false ] If the parent should be notified.
      #
      # @since 2.1.0
      def notifying_parent?
        @notifying_parent ||= !@options.delete(:suppress)
      end

      # Get all the options that will be sent to the database. Right now this
      # is only safe mode opts.
      #
      # @example Get the options hash.
      #   operation.options
      #
      # @return [ Hash ] The options for the database.
      #
      # @since 2.1.0
      def options
        { :safe => @options[:safe] || Mongoid.persist_in_safe_mode }
      end

      # Get the parent of the provided document.
      #
      # @example Get the parent.
      #   operation.parent
      #
      # @return [ Document ] The parent document.
      #
      # @since 2.1.0
      def parent
        document._parent
      end

      # Should we be running validations on this persistence operation?
      # Defaults to true.
      #
      # @example Run validations?
      #   operation.validating?
      #
      # @return [ true, false ] If we run validations.
      #
      # @since 2.1.0
      def validating?
        @validating ||= @options[:validate].nil? ? true : @options[:validate]
      end
    end
  end
end
