# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Timestamps

    # This module adds behavior for turning off timestamping in single or
    # multiple calls.
    module Timeless
      extend ActiveSupport::Concern

      # Clears out the timeless option.
      #
      # @example Clear the timeless option.
      #   document.clear_timeless_option
      #
      # @return [ true ] True.
      def clear_timeless_option
        if self.persisted?
          self.class.clear_timeless_option_on_update
        else
          self.class.clear_timeless_option
        end
        true
      end

      # Begin an execution that should skip timestamping.
      #
      # @example Save a document but don't timestamp.
      #   person.timeless.save
      #
      # @return [ Document ] The document this was called on.
      def timeless
        self.class.timeless
        self
      end

      # Returns whether the document should skip timestamping.
      #
      # @return [ true | false ] Whether the document should
      #   skip timestamping.
      def timeless?
        self.class.timeless?
      end

      class << self
        extend Forwardable

        # Returns the in-memory thread cache of classes
        # for which to skip timestamping.
        #
        # @return [ Hash ] The timeless table.
        #
        # @api private
        def timeless_table
          Thread.current['[mongoid]:timeless'] ||= Hash.new
        end

        def_delegators :timeless_table, :[]=, :[]
      end

      private

      module ClassMethods

        # Begin an execution that should skip timestamping.
        #
        # @example Create a document but don't timestamp.
        #   Person.timeless.create(:title => "Sir")
        #
        # @return [ Class ] The class this was called on.
        def timeless
          counter = 0
          counter += 1 if self < Mongoid::Timestamps::Created
          counter += 1 if self < Mongoid::Timestamps::Updated
          Timeless[name] = counter
          self
        end

        # Removes the timeless option on the current class.
        #
        # @return [ true ] Always true.
        def clear_timeless_option
          if counter = Timeless[name]
            counter -= 1
            set_timeless_counter(counter)
          end
          true
        end

        # Sets to remove the timeless option when the next
        # instance of the current class is updated.
        #
        # @return [ true ] Always true.
        def clear_timeless_option_on_update
          if counter = Timeless[name]
            counter -= 1 if self < Mongoid::Timestamps::Created
            counter -= 1 if self < Mongoid::Timestamps::Updated
            set_timeless_counter(counter)
          end
        end

        # Clears the timeless counter for the current class
        # if the value has reached zero.
        #
        # @param [ Integer ] counter The counter value.
        #
        # @return [ Integer | nil ] The counter value, or nil
        #   if the counter was cleared.
        def set_timeless_counter(counter)
          Timeless[name] = (counter == 0) ? nil : counter
        end

        # Returns whether the current class should skip timestamping.
        #
        # @return [ true | false ] Whether the current class should
        #   skip timestamping.
        def timeless?
          !!Timeless[name]
        end
      end
    end
  end
end
