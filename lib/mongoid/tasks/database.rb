# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Tasks
    module Database
      extend self

      # Create indexes for each model given the provided globs and the class is
      # not embedded.
      #
      # @example Create all the indexes.
      #   Mongoid::Tasks::Database.create_indexes
      #
      # @return [ Array<Class> ] The indexed models.
      #
      # @since 2.1.0
      def create_indexes(models = ::Mongoid.models)
        models.each do |model|
          next if model.index_specifications.empty?
          if !model.embedded? || model.cyclic?
            model.create_indexes
            logger.info("MONGOID: Created indexes on #{model}:")
            model.index_specifications.each do |spec|
              logger.info("MONGOID: Index: #{spec.key}, Options: #{spec.options}")
            end
            model
          else
            logger.info("MONGOID: Index ignored on: #{model}, please define in the root model.")
            nil
          end
        end.compact
      end

      # Return the list of indexes by model that exist in the database but aren't
      # specified on the models.
      #
      # @example Return the list of unused indexes.
      #   Mongoid::Tasks::Database.undefined_indexes
      #
      # @return [ Array<Hash> ] The list of undefined indexes by model.
      #
      def undefined_indexes(models = ::Mongoid.models)
        undefined_by_model = {}

        models.each do |model|
          unless model.embedded?
            begin
              model.collection.indexes(session: model.send(:_session)).each do |index|
                # ignore default index
                unless index['name'] == '_id_'
                  key = index['key'].symbolize_keys
                  spec = model.index_specification(key, index['name'])
                  unless spec
                    # index not specified
                    undefined_by_model[model] ||= []
                    undefined_by_model[model] << index
                  end
                end
              end
            rescue Mongo::Error::OperationFailure; end
          end
        end

        undefined_by_model
      end

      # Prints a list of indexes to the logger, including missing and undefined indexes.
      #
      # @example Print list of indexes.
      #   Mongoid::Tasks::Database.list_indexes
      #
      # @return [ Array(Class, Array(Hash)) ] The models and categorized indexes that were listed.
      #
      # @since 6.0.0
      def list_indexes(models = ::Mongoid.models)
        indexes = diffed_indexes(models).to_a
        indexes.sort_by! { |index| "#{diff_sort(index[1])}#{index[0]}" }
        indexes.each do |model, diff|
          logger.info "#{model.to_s.ljust(50)} #{diff_status(diff)}"

          if diff[:ok]
            if (diff.keys - [:ok]).present?
              logger.info "  OK"
              log_index_specifications(diff[:ok])
            else
              log_index_specifications(diff[:ok], 2)
            end
          end

          if diff[:conflict]
            logger.info "  CONFLICT"
            log_index_specifications(diff[:conflict])
          end

          if diff[:missing]
            logger.info "  MISSING"
            log_index_specifications(diff[:missing])
          end

          if diff[:undefined]
            logger.info "  UNDEFINED"
            log_indexes(diff[:undefined])
          end

          logger.info ''
        end
      end

      # Remove indexes that exist in the database but aren't specified on the
      # models.
      #
      # @example Remove undefined indexes.
      #   Mongoid::Tasks::Database.remove_undefined_indexes
      #
      # @return [ Hash{Class => Array(Hash)}] The list of indexes that were removed by model.
      #
      # @since 4.0.0
      def remove_undefined_indexes(models = ::Mongoid.models)
        undefined_indexes(models).each do |model, indexes|
          indexes.each do |index|
            key = index['key'].symbolize_keys
            collection = model.collection
            collection.indexes(session: model.send(:_session)).drop_one(key)
            logger.info(
              "MONGOID: Removed index '#{index['name']}' on collection " +
              "'#{collection.name}' in database '#{collection.database.name}'."
            )
          end
        end
      end

      # Remove indexes for each model given the provided globs and the class is
      # not embedded.
      #
      # @example Remove all the indexes.
      #   Mongoid::Tasks::Database.remove_indexes
      #
      # @return [ Array<Class> ] The un-indexed models.
      #
      def remove_indexes(models = ::Mongoid.models)
        models.each do |model|
          next if model.embedded?
          begin
            model.remove_indexes
          rescue Mongo::Error::OperationFailure
            next
          end
          model
        end.compact
      end

      private

      def logger
        Mongoid.logger
      end

      def log_indexes(indexes, indent=4)
        indexes.each{ |index| logger.info("#{' '*indent}#{index['name']}") }
      end

      def log_index_specifications(indexes, indent=4)
        indexes.each{ |index| logger.info("#{' '*indent}#{index.key}#{', ' + index.options.to_s unless index.options.empty?}".gsub(/:(.*?)=>/, '\1: ')) }
      end

      # Return a nested Hash of indexes by model then by status:
      # - ok: Defined in model and exists in database.
      # - conflict: The options of the model-defined index are different than the database index.
      # - missing: Defined in model but does not exist in database.
      # - undefined: Exists in database but not defined in model.
      #
      # @example Return the list of nonexistent indexes.
      #   Mongoid::Tasks::Database.diffed_indexes
      #
      # @return Hash{Class => Hash{Symbol => Array()}} The list of indexes by model then by status.
      #
      # @since 6.0.0
      def diffed_indexes(models = ::Mongoid.models)
        indexes_by_model = {}
        valid_options = ::Mongoid::Indexable::Validators::Options::VALID_OPTIONS - [:key, :name]

        models.each do |model|
          next if model.embedded?
          indexes_by_model[model] ||= {}
          indexes_by_model[model][:missing] = model.index_specifications.dup
          begin
            model.collection.indexes.each do |index|
              next if index['name'] == '_id_'
              key = index['key'].symbolize_keys
              spec = model.index_specification(key, index['name'])
              if spec
                indexes_by_model[model][:missing] -= [spec]
                spec_options  = spec.options.symbolize_keys.slice(*valid_options).sort
                index_options = index.symbolize_keys.slice(*valid_options).sort
                if spec_options == index_options
                  indexes_by_model[model][:ok] ||= []
                  indexes_by_model[model][:ok] << spec
                else
                  indexes_by_model[model][:conflict] ||= []
                  indexes_by_model[model][:conflict] << spec
                end
              else
                indexes_by_model[model][:undefined] ||= []
                indexes_by_model[model][:undefined] << index
              end
            end
          rescue Mongo::Error::OperationFailure; end

          indexes_by_model[model].delete(:missing) if indexes_by_model[model][:missing].empty?
        end

        indexes_by_model
      end

      # Returns a human-readable status of an index diff
      #
      # @return String The status.
      #
      # @since 6.0.0
      def diff_status(diff)
        if diff.blank?
          'NONE'
        elsif (diff.keys - [:ok]).present?
          'BAD'
        else
          'OK'
        end
      end

      # Returns sort order of an index diff
      #
      # @return Integer The sort order.
      #
      # @since 6.0.0
      def diff_sort(diff)
        case diff_status(diff)
          when 'OK'   then 0
          when 'NONE' then 1
          when 'BAD'  then 2
        end
      end
    end
  end
end
