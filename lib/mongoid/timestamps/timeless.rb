# encoding: utf-8
module Mongoid
  module Timestamps

    # This module adds behaviour for turning off timestamping in single or
    # multiple calls.
    module Timeless
      extend ActiveSupport::Concern

      # Clears out the timeless option.
      #
      # @example Clear the timeless option.
      #   document.clear_timeless_option
      #
      # @return [ true ] True.
      #
      # @since 3.1.4
      def clear_timeless_option
        self.class.clear_timeless_option
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
        self.class.timeless
        self
      end

      def timeless?
        self.class.timeless?
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
          counter = 0
          counter += 1 if self < Mongoid::Timestamps::Created
          counter += 1 if self < Mongoid::Timestamps::Updated
          Thread.current["[mongoid]:[#{name}]:timeless"] = counter
          self
        end

        def clear_timeless_option
          if counter = Thread.current["[mongoid]:[#{name}]:timeless"]
            counter -= 1
            Thread.current["[mongoid]:[#{name}]:timeless"] =
              (counter == 0) ? nil : counter
          end
          true
        end

        def timeless?
          !!Thread.current["[mongoid]:[#{name}]:timeless"]
        end

      end
    end
  end
end
