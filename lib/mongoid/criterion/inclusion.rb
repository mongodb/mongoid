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
        clone.tap do |crit|
          criterion = @selector["$or"] || []
          converted = BSON::ObjectId.convert(klass, args.flatten)
          expanded = converted.collect(&:expand_complex_criteria)
          crit.selector["$or"] = criterion.concat(expanded)
        end
      end
      alias :or :any_of

      # Find the matchind document in the criteria, either based on id or
      # conditions.
      #
      # @todo Durran: DRY up duplicated code in a few places.
      #
      # @example Find by an id.
      #   criteria.find(BSON::ObjectId.new)
      #
      # @example Find by multiple ids.
      #   criteria.find([ BSON::ObjectId.new, BSON::ObjectId.new ])
      #
      # @example Conditionally find all matching documents.
      #   criteria.find(:all, :conditions => { :title => "Sir" })
      #
      # @example Conditionally find the first document.
      #   criteria.find(:first, :conditions => { :title => "Sir" })
      #
      # @example Conditionally find the last document.
      #   criteria.find(:last, :conditions => { :title => "Sir" })
      #
      # @param [ Symbol, BSON::ObjectId, Array<BSON::ObjectId> ] arg The
      #   argument to search with.
      # @param [ Hash ] options The options to search with.
      #
      # @return [ Document, Criteria ] The matching document(s).
      def find(*args)
        type, crit = search(*args)
        case type
        when :first then crit.one
        when :last then crit.last
        when :ids then execute_or_raise(args, crit)
        else
          crit
        end
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

          selector.each_pair do |key, value|
            if crit.selector.has_key?(key) && crit.selector[key].respond_to?(:merge!)
              crit.selector[key] =
                crit.selector[key].merge!(value) do |key, old, new|
                  key == '$in' ? old & new : new
                end
            else
              crit.selector[key] = value
            end
          end
        end
      end

      private

      # Execute the criteria or raise an error if no documents found.
      #
      # @example Execute or raise
      #   criteria.execute_or_raise(id, criteria)
      #
      # @param [ Object ] args The arguments passed.
      # @param [ Criteria ] criteria The criteria to execute.
      #
      # @raise [ Errors::DocumentNotFound ] If nothing returned.
      #
      # @return [ Document, Array<Document> ] The document(s).
      #
      # @since 2.0.0
      def execute_or_raise(args, criteria)
        (args[0].is_a?(Array) ? criteria.entries : criteria.one).tap do |result|
          if Mongoid.raise_not_found_error && !args.flatten.blank?
            raise Errors::DocumentNotFound.new(klass, args) if result.blank?
          end
        end
      end
    end
  end
end
