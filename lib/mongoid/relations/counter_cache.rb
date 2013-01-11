# encoding: utf-8
module Mongoid
  module Relations
    module CounterCache
      extend ActiveSupport::Concern

      module ClassMethods

        # Reset the given counter using the .count() query from the
        # db. This method is usuful in case that a counter got
        # corrupted, or a new counter was added to the collection.
        #
        # @example Reset the given counter cache
        #   Post.reset_counters('50e0edd97c71c17ea9000001', :comments)
        #
        # @param [ String ] The id of the object that will be reset.
        # @param [ Symbol, Array ] One or more counter caches to reset
        #
        # @since 3.1.0
        def reset_counters(id, *counters)
          object = find(id)
          counters.each do |name|
            reflection_meta = reflect_on_association(name)
            meta = reflection_meta.klass.reflect_on_association(reflection_meta.inverse)
            counter_name = meta.counter_cache_column_name
            object.update_attribute(counter_name, object.send(name).count)
          end
        end

        # Update the given counters by the value factor. It uses the
        # atomic $inc command.
        #
        # @example Add 5 to comments counter and remove 2 from likes
        # counter
        #
        #   Post.update_counters('50e0edd97c71c17ea9000001',
        #              :comments_count => 5, :likes_count => -2)
        #
        # @param [ String ] The id of the object to update.
        # @param [ Hash ] Key = counter_cahe and Value = factor.
        #
        # @since 3.1.0
        def update_counters(id, counters)
          counters.map do |key, value|
            where(:_id => id).inc(key, value)
          end
        end

        # Increment the counter name from the entries that match the
        # id by one. This method is used on associations callbacks
        # when counter_cache is enable
        #
        # @example Increment comments counter
        #
        #   Post.increment_counter(:comments_count, '50e0edd97c71c17ea9000001')
        #
        # @param [ Symbol ] Counter cache name
        # @param [ String ] The id of the object that will be reset.
        #
        # @since 3.1.0
        def increment_counter(counter_name, id)
          update_counters(id, counter_name.to_sym => 1)
        end


        # Decrement the counter name from the entries that match the
        # id by one. This method is used on associations callbacks
        # when counter_cache is enable
        #
        # @example Decrement comments counter
        #
        #   Post.decrement_counter(:comments_count, '50e0edd97c71c17ea9000001')
        #
        # @param [ Symbol ] Counter cache name
        # @param [ String ] The id of the object that will be reset.
        #
        # @since 3.1.0
        def decrement_counter(counter_name, id)
          update_counters(id, counter_name.to_sym => -1)
        end

      end

    end
  end
end
