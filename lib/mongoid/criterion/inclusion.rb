# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Inclusion

      # Adds a criterion to the +Criteria+ that specifies values that must all
      # be matched in order to return results. Similar to an "in" clause but the
      # underlying conditional logic is an "AND" and not an "OR". The MongoDB
      # conditional operator that will be used is "$all".
      #
      # @example Adding the criterion.
      #   criteria.all(:field => ["value1", "value2"])
      #   criteria.all(:field1 => ["value1", "value2"], :field2 => ["value1"])
      #
      # @param [ Hash ] attributes Name/value pairs that all must match.
      #
      # @return [ Criteria ] A new criteria with the added selector.
      def all(attributes = {})
        update_selector(attributes, "$all")
      end
      alias :all_in :all

      # Adds a criterion to the criteria that specifies multiple expressions
      # that *all* must match. This uses MongoDB's $and operator under the
      # covers.
      #
      # @example Match all provided expressions.
      #   criteria.all_of(:name => value, :age.gt => 18)
      #
      # @param [ Array<Hash> ] Multiple hash expressions.
      #
      # @return [ Criteria ] The criteria object.
      #
      # @since 2.3.0
      def all_of(*args)
        multi_selection("$and", *args)
      end

      # Adds a criterion to the +Criteria+ that specifies values where any can
      # be matched in order to return results. This is similar to an SQL "IN"
      # clause. The MongoDB conditional operator that will be used is "$in".
      # Any previously matching "$in" arrays will be unioned with new
      # arguments.
      #
      # @example Adding the criterion.
      #   criteria.in(:field => ["value1"]).also_in(:field => ["value2"])
      #
      # @param [ Hash ] attributes Name/value pairs any can match.
      #
      # @return [ Criteria ] A new criteria with the added selector.
      def also_in(attributes = {})
        update_selector(attributes, "$in")
      end

      # Adds a criterion to the +Criteria+ that specifies values that must
      # be matched in order to return results. This is similar to a SQL "WHERE"
      # clause. This is the actual selector that will be provided to MongoDB,
      # similar to the Javascript object that is used when performing a find()
      # in the MongoDB console.
      #
      # @example Adding the criterion.
      #   criteria.and(:field1 => "value1", :field2 => 15)
      #
      # @param [ Hash ] selectior Name/value pairs that all must match.
      #
      # @return [ Criteria ] A new criteria with the added selector.
      def and(selector = nil)
        where(selector)
      end

      # Adds a criterion to the +Criteria+ that specifies a set of expressions
      # to match if any of them return true. This is a $or query in MongoDB and
      # is similar to a SQL OR. This is named #any_of and aliased "or" for
      # readability.
      #
      # @example Adding the criterion.
      #   criteria.any_of({ :field1 => "value" }, { :field2 => "value2" })
      #
      # @param [ Array<Hash> ] args A list of name/value pairs any can match.
      #
      # @return [ Criteria ] A new criteria with the added selector.
      def any_of(*args)
        multi_selection("$or", *args)
      end
      alias :or :any_of

      # Find the matchind document(s) in the criteria for the provided ids.
      #
      # @example Find by an id.
      #   criteria.find(BSON::ObjectId.new)
      #
      # @example Find by multiple ids.
      #   criteria.find([ BSON::ObjectId.new, BSON::ObjectId.new ])
      #
      # @param [ Array<BSON::ObjectId> ] args The ids to search for.
      #
      # @return [ Array<Document>, Document ] The matching document(s).
      def find(*args)
        ids = args.flat_map{ |arg| arg.is_a?(::Range) ? arg.to_a : arg }
        raise_invalid if ids.any?(&:nil?)
        for_ids(ids).execute_or_raise(args)
      end

      # Execute the criteria or raise an error if no documents found.
      #
      # @example Execute or raise
      #   criteria.execute_or_raise(id)
      #
      # @param [ Object ] args The arguments passed.
      #
      # @raise [ Errors::DocumentNotFound ] If nothing returned.
      #
      # @return [ Document, Array<Document> ] The document(s).
      #
      # @since 2.0.0
      def execute_or_raise(args)
        ids = args[0]
        ids = ids.to_a if ids.is_a?(::Range)
        if ids.is_a?(::Array)
          entries.tap do |result|
            if (entries.size < ids.size) && Mongoid.raise_not_found_error
              missing = ids - entries.map(&:_id)
              raise Errors::DocumentNotFound.new(klass, ids, missing)
            end
          end
        else
          from_map_or_db.tap do |result|
            if result.nil? && ids && Mongoid.raise_not_found_error
              raise Errors::DocumentNotFound.new(klass, ids, ids)
            end
          end
        end
      end

      # Get the document from the identity map, and if not found hit the
      # database.
      #
      # @example Get the document from the map or criteria.
      #   criteria.from_map_or_db(criteria)
      #
      # @param [ Criteria ] The cloned criteria.
      #
      # @return [ Document ] The found document.
      #
      # @since 2.2.1
      def from_map_or_db
        doc = IdentityMap.get(klass, extract_id || selector)
        doc && doc.matches?(selector) ? doc : first
      end

      # Adds a criterion to the +Criteria+ that specifies values where any can
      # be matched in order to return results. This is similar to an SQL "IN"
      # clause. The MongoDB conditional operator that will be used is "$in".
      #
      # @example Adding the criterion.
      #   criteria.in(:field => ["value1", "value2"])
      #   criteria.in(:field1 => ["value1", "value2"], :field2 => ["value1"])
      #
      # @param [ Hash ] attributes Name/value pairs any can match.
      #
      # @return [ Criteria ] A new criteria with the added selector.
      def in(attributes = {})
        update_selector(attributes, "$in", :&)
      end
      alias :any_in :in

      # Eager loads all the provided relations. Will load all the documents
      # into the identity map who's ids match based on the extra query for the
      # ids.
      #
      # @note This will only work if Mongoid's identity map is enabled. To do
      #   so set identity_map_enabled: true in your mongoid.yml
      #
      # @note This will work for embedded relations that reference another
      #   collection via belongs_to as well.
      #
      # @note Eager loading brings all the documents into memory, so there is a
      #   sweet spot on the performance gains. Internal benchmarks show that
      #   eager loading becomes slower around 100k documents, but this will
      #   naturally depend on the specific application.
      #
      # @example Eager load the provided relations.
      #   Person.includes(:posts, :game)
      #
      # @param [ Array<Symbol> ] relations The names of the relations to eager
      #   load.
      #
      # @return [ Criteria ] The cloned criteria.
      #
      # @since 2.2.0
      def includes(*relations)
        relations.flatten.each do |name|
          inclusions.push(klass.reflect_on_association(name))
        end
        clone
      end

      # Get a list of criteria that are to be executed for eager loading.
      #
      # @example Get the eager loading inclusions.
      #   Person.includes(:game).inclusions
      #
      # @return [ Array<Metadata> ] The inclusions.
      #
      # @since 2.2.0
      def inclusions
        @inclusions ||= []
      end

      def inclusions=(value)
        @inclusions = value
      end

      # Adds a criterion to the +Criteria+ that specifies values to do
      # geospacial searches by. The field must be indexed with the "2d" option.
      #
      # @example Adding the criterion.
      #   criteria.near(:field1 => [30, -44])
      #
      # @param [ Hash ] attributes The fields with lat/long values.
      #
      # @return [ Criteria ] A new criteria with the added selector.
      def near(attributes = {})
        update_selector(attributes, "$near")
      end

      # Adds a criterion to the +Criteria+ that specifies values that must
      # be matched in order to return results. This is similar to a SQL "WHERE"
      # clause. This is the actual selector that will be provided to MongoDB,
      # similar to the Javascript object that is used when performing a find()
      # in the MongoDB console.
      #
      # @example Adding the criterion.
      #   criteria.where(:field1 => "value1", :field2 => 15)
      #
      # @param [ Hash ] selector Name/value pairs where all must match.
      #
      # @return [ Criteria ] A new criteria with the added selector.
      def where(selector = nil)
        clone.tap do |crit|
          selector = case selector
            when String then {"$where" => selector}
            else
              BSON::ObjectId.convert(klass, selector || {}, false).expand_complex_criteria
          end

          # @todo: Durran: 3.0.0: refactor the merging into separate strategies
          # to clean this funkiness up.
          selector.each_pair do |key, value|
            if crit.selector.has_key?(key)
              if key.mongoid_id?
                if crit.selector.has_key?("$and")
                  crit.selector["$and"] << { key => value }
                else
                  crit.selector["$and"] = [{ key => crit.selector.delete(key) }, { key => value }]
                end
              elsif crit.selector[key].respond_to?(:merge) && value.respond_to?(:merge)
                crit.selector[key] =
                  crit.selector[key].merge(value) do |_key, old, new|
                    _key == '$in' ? old & new : new
                  end
              else
                crit.selector[key] = value
              end
            else
              crit.selector[key] = value
            end
          end
        end
      end

      private

      def multi_selection(command, *args)
        clone.tap do |crit|
          unless args.empty?
            criterion = @selector[command] || []
            converted = BSON::ObjectId.convert(klass, args.flatten)
            expanded = converted.collect { |hash| hash.expand_complex_criteria }
            crit.selector[command] = criterion.concat(expanded)
          end
        end
      end
    end
  end
end
