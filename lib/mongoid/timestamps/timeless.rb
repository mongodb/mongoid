# encoding: utf-8
module Mongoid
  module Timestamps

    # This module adds behaviour for turning off timestamping in single or
    # multiple calls.
    module Timeless
      extend ActiveSupport::Concern

      included do
        class_attribute :timestamping
        self.timestamping = true
      end

      # Clears out the timeless option.
      #
      # @example Clear the timeless option.
      #   document.clear_timeless_option
      #
      # @return [ true ] True.
      #
      # @since 3.1.4
      def clear_timeless_option
        self.class.timestamping = true
      end

      # Begin an execution that should skip timestamping.
      #
      # @example Save a document but don't timestamp.
      #   person.timeless.save
      #
      # @return [ Document ] The document this was called on.
      #
      # @since 2.3.0
      def timeless
        self.class.timestamping = false
        self
      end

      private

      module ClassMethods

        # Begin an execution that should skip timestamping.
        #
        # @example Create a document but don't timestamp.
        #   Person.timeless.create(:title => "Sir")
        #
        # @return [ Class ] The class this was called on.
        #
        # @since 2.3.0
        def timeless
          self.timestamping = false
          self
        end
      end
    end
  end
end
