# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      module CounterCache
        extend ActiveSupport::Concern

        # Reset the given counter using the .count() query from the
        # db. This method is useful in case that a counter got
        # corrupted, or a new counter was added to the collection.
        #
        # @example Reset the given counter cache
        #   post.reset_counters(:comments)
        #
        # @param [ Symbol... ] *counters One or more counter caches to reset.
        def reset_counters(*counters)
          self.class.with(persistence_context) do |_class|
            _class.reset_counters(self, *counters)
          end
        end

        module ClassMethods

          # Reset the given counter using the .count() query from the
          # db. This method is useful in case that a counter got
          # corrupted, or a new counter was added to the collection.
          #
          # @example Reset the given counter cache
          #   Post.reset_counters('50e0edd97c71c17ea9000001', :comments)
          #
          # @param [ String ] id The id of the object that will be reset.
          # @param [ Symbol... ] *counters One or more counter caches to reset.
          def reset_counters(id, *counters)
            document = id.is_a?(Document) ? id : find(id)
            counters.each do |name|
              relation_association = relations[name]
              counter_name = relation_association.inverse_association.counter_cache_column_name
              document.update_attribute(counter_name, document.send(name).count)
            end
          end

          # Update the given counters by the value factor. It uses the
          # atomic $inc command.
          #
          # @example Add 5 to comments counter and remove 2 from likes
          #   counter.
          #   Post.update_counters('50e0edd97c71c17ea9000001',
          #              :comments_count => 5, :likes_count => -2)
          #
          # @param [ String ] id The id of the object to update.
          # @param [ Hash ] counters
          def update_counters(id, counters)
            where(:_id => id).inc(counters)
          end

          # Increment the counter name from the entries that match the
          # id by one. This method is used on associations callbacks
          # when counter_cache is enabled
          #
          # @example Increment comments counter
          #   Post.increment_counter(:comments_count, '50e0edd97c71c17ea9000001')
          #
          # @param [ Symbol ] counter_name Counter cache name
          # @param [ String ] id The id of the object that will have its counter incremented.
          def increment_counter(counter_name, id)
            update_counters(id, counter_name.to_sym => 1)
          end

          # Decrement the counter name from the entries that match the
          # id by one. This method is used on associations callbacks
          # when counter_cache is enabled
          #
          # @example Decrement comments counter
          #   Post.decrement_counter(:comments_count, '50e0edd97c71c17ea9000001')
          #
          # @param [ Symbol ] counter_name Counter cache name
          # @param [ String ] id The id of the object that will have its counter decremented.
          def decrement_counter(counter_name, id)
            update_counters(id, counter_name.to_sym => -1)
          end
        end

        # Add the callbacks responsible for update the counter cache field.
        #
        # @api private
        #
        # @example Add the touchable.
        #   Mongoid::Association::Referenced::CounterCache.define_callbacks!(association)
        #
        # @param [ Association ] association The association.
        #
        # @return [ Class ] The association's owning class.
        def self.define_callbacks!(association)
          name = association.name
          cache_column = association.counter_cache_column_name.to_sym

          association.inverse_class.tap do |klass|
            klass.after_update do
              foreign_key = association.foreign_key

              if send("#{foreign_key}_previously_changed?")
                original, current = send("#{foreign_key}_previous_change")

                unless original.nil?
                  association.klass.with(persistence_context) do |_class|
                    _class.decrement_counter(cache_column, original)
                  end
                end

                if record = __send__(name)
                  unless current.nil?
                    record[cache_column] = (record[cache_column] || 0) + 1
                    record.class.with(record.persistence_context) do |_class|
                      _class.increment_counter(cache_column, current) if record.persisted?
                    end
                  end
                end
              end
            end

            klass.after_create do
              if record = __send__(name)
                record[cache_column] = (record[cache_column] || 0) + 1

                if record.persisted?
                  record.class.with(record.persistence_context) do |_class|
                    _class.increment_counter(cache_column, record._id)
                  end
                  record.remove_change(cache_column)
                end
              end
            end

            klass.before_destroy do
              if record = __send__(name)
                record[cache_column] = (record[cache_column] || 0) - 1 unless record.frozen?

                if record.persisted?
                  record.class.with(record.persistence_context) do |_class|
                    _class.decrement_counter(cache_column, record._id)
                  end
                  record.remove_change(cache_column)
                end
              end
            end
          end
        end
      end
    end
  end
end
