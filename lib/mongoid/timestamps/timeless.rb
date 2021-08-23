# frozen_string_literal: true

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

      def timeless?
        self.class.timeless?
      end

      class << self
        extend Forwardable

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

        def clear_timeless_option
          if counter = Timeless[name]
            counter -= 1
            set_timeless_counter(counter)
          end
          true
        end

        def clear_timeless_option_on_update
          if counter = Timeless[name]
            counter -= 1 if self < Mongoid::Timestamps::Created
            counter -= 1 if self < Mongoid::Timestamps::Updated
            set_timeless_counter(counter)
          end
        end

        def set_timeless_counter(counter)
          Timeless[name] = (counter == 0) ? nil : counter
        end

        def timeless?
          !!Timeless[name]
        end
      end
    end
  end
end
