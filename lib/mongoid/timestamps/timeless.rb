# encoding: utf-8
module Mongoid #:nodoc:
  module Timestamps

    # This module adds behaviour for turning off timestamping in single or
    # multiple calls.
    module Timeless
      extend ActiveSupport::Concern

      # Begin an execution that should skip timestamping.
      #
      # @example Save a document but don't timestamp.
      #   person.timeless.save
      #
      # @return [ Document ] The document this was called on.
      #
      # @since 2.3.0
      def timeless
        tap { Threaded.timeless = true }
      end

      # Are we currently timestamping?
      #
      # @example Should timestamps be applied?
      #   person.timestamping?
      #
      # @return [ true, false ] If the current thread is timestamping.
      #
      # @since 2.3.0
      def timestamping?
        Threaded.timestamping?
      end

      module ClassMethods #:nodoc

        # Begin an execution that should skip timestamping.
        #
        # @example Create a document but don't timestamp.
        #   Person.timeless.create(:title => "Sir")
        #
        # @return [ Class ] The class this was called on.
        #
        # @since 2.3.0
        def timeless
          tap { Threaded.timeless = true }
        end
      end
    end
  end
end
