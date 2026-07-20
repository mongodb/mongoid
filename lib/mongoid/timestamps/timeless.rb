# frozen_string_literal: true

module Mongoid
  module Timestamps
    # This module adds behavior for turning off timestamping in single or
    # multiple calls.
    module Timeless
      extend ActiveSupport::Concern

      # Deprecator for the block-less form of the timeless API. Its removal
      # horizon is computed automatically as (current major + 1).0.
      DEPRECATION = Mongoid::Deprecation.new

      # Clears out the timeless option.
      #
      # @example Clear the timeless option.
      #   document.clear_timeless_option
      #
      # @return [ true ] True.
      def clear_timeless_option
        if persisted?
          self.class.clear_timeless_option_on_update
        else
          self.class.clear_timeless_option
        end
        true
      end

      # Skip timestamping for the duration of the given block, or (in the
      # deprecated, block-less form) for the next persistence operation.
      #
      # @example Save a document but don't timestamp (block form).
      #   person.timeless { person.save }
      #
      # @example Save a document but don't timestamp (deprecated chained form).
      #   person.timeless.save
      #
      # @return [ Object | Document ] The return value of the block, or (in the
      #   block-less form) the document this was called on.
      def timeless(&block)
        return Timeless.with_timeless(&block) if block

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

        # The key to use to store the timeless table
        TIMELESS_TABLE_KEY = '[mongoid]:timeless'

        # The key to use to store the block-based timeless flag.
        TIMELESS_FLAG_KEY = '[mongoid]:timeless-flag'

        # Returns the in-memory thread cache of classes
        # for which to skip timestamping.
        #
        # @return [ Hash ] The timeless table.
        #
        # @api private
        def timeless_table
          Threaded.get(TIMELESS_TABLE_KEY) { {} }
        end

        def_delegators :timeless_table, :[]=, :[]

        # Skip timestamping for the duration of the given block, on the
        # current thread or fiber. This applies to every document persisted
        # while the block is executing, regardless of class, including
        # cascaded embedded children at any nesting depth.
        #
        # @example Skip timestamping for a block.
        #   Mongoid::Timestamps::Timeless.with_timeless do
        #     person.save
        #   end
        #
        # @return [ Object ] The return value of the block.
        def with_timeless
          # Only the outermost block owns the flag: if we are already inside a
          # timeless scope, we leave the suppression in place when this block
          # ends. This avoids tracking a nesting depth that could drift out of
          # sync.
          already_timeless = suppressing_timestamps?
          set_suppressing_timestamps(true) unless already_timeless
          yield
        ensure
          set_suppressing_timestamps(false) unless already_timeless
        end

        # Whether a block-based timeless scope is currently active on this
        # thread/fiber.
        #
        # @return [ true | false ] Whether timestamps are being suppressed.
        #
        # @api private
        def suppressing_timestamps?
          !!Threaded.get(TIMELESS_FLAG_KEY) { false }
        end

        # Set whether a block-based timeless scope is active on this
        # thread/fiber.
        #
        # @param [ true | false ] value Whether to suppress timestamps.
        #
        # @api private
        def set_suppressing_timestamps(value)
          Threaded.set(TIMELESS_FLAG_KEY, value)
        end
      end

      module ClassMethods
        # Skip timestamping for the duration of the given block, or (in the
        # deprecated, block-less form) for the next persistence operation.
        #
        # @example Create a document but don't timestamp (block form).
        #   Person.timeless { Person.create(title: "Sir") }
        #
        # @example Create a document but don't timestamp (deprecated form).
        #   Person.timeless.create(:title => "Sir")
        #
        # @return [ Object | Class ] The return value of the block, or (in the
        #   block-less form) the class this was called on.
        def timeless(&block)
          return Timeless.with_timeless(&block) if block

          DEPRECATION.warn(
            'Calling #timeless without a block is deprecated; pass a block ' \
            'instead, e.g. `record.timeless { record.save }`.'
          )
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
          return unless counter = Timeless[name]

          counter -= 1 if self < Mongoid::Timestamps::Created
          counter -= 1 if self < Mongoid::Timestamps::Updated
          set_timeless_counter(counter)
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

        # Returns whether the current class should skip timestamping. This is
        # true when either a block-based timeless scope is active on the
        # current thread/fiber, or the deprecated per-class counter is set.
        #
        # @return [ true | false ] Whether the current class should
        #   skip timestamping.
        def timeless?
          Timeless.suppressing_timestamps? || !!Timeless[name]
        end
      end
    end
  end
end
