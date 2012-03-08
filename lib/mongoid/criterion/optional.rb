# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Optional

      # Tells the criteria that the cursor that gets returned needs to be
      # cached. This is so multiple iterations don't hit the database multiple
      # times, however this is not advisable when working with large data sets
      # as the entire results will get stored in memory.
      #
      # @example Flag the criteria as cached.
      #   criteria.cache
      #
      # @return [ Criteria ] The cloned criteria.
      def cache
        clone.tap { |crit| crit.options.merge!(cache: true) }
      end

      # Will return true if the cache option has been set.
      #
      # @example Is the criteria cached?
      #   criteria.cached?
      #
      # @return [ true, false ] If the criteria is flagged as cached.
      def cached?
        options[:cache] == true
      end

      # Adds a criterion to the +Criteria+ that specifies additional options
      # to be passed to the Ruby driver, in the exact format for the driver.
      #
      # @example Add extra params to the criteria.
      #   criteria.extras(:limit => 20, :skip => 40)
      #
      # @param [ Hash ] extras The extra driver options.
      #
      # @return [ Criteria ] The cloned criteria.
      def extras(extras)
        clone.tap do |crit|
          crit.options.merge!(extras)
        end
      end

      # Adds a criterion to the +Criteria+ that specifies an id that must be matched.
      #
      # @example Add a single id criteria.
      #   criteria.for_ids("4ab2bc4b8ad548971900005c")
      #
      # @example Add multiple id criteria.
      #   criteria.for_ids(["4ab2bc4b8ad548971900005c", "4c454e7ebf4b98032d000001"])
      #
      # @param [ Array ] ids: A single id or an array of ids.
      #
      # @return [ Criteria ] The cloned criteria.
      def for_ids(*ids)
        field = klass.fields["_id"]
        ids.flatten!
        method = extract_id ? :all_of : :where
        if ids.size > 1
          send(method, { _id: { "$in" => ids.map{ |id| field.serialize(id) }}})
        else
          send(method, { _id: field.serialize(ids.first) })
        end
      end

      # Adds a criterion to the +Criteria+ that specifies a type or an Array of
      # types that must be matched.
      #
      # @example Match only specific models.
      #   criteria.type('Browser')
      #   criteria.type(['Firefox', 'Browser'])
      #
      # @param [ Array<String> ] types The types to match against.
      #
      # @return [ Criteria ] The cloned criteria.
      def type(types)
        types = [types] unless types.is_a?(Array)
        any_in(_type: types)
      end
    end
  end
end
