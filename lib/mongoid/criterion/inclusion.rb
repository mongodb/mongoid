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
          expanded = args.collect(&:expand_complex_criteria)
          crit.selector["$or"] = criterion.concat(expanded)
        end
      end
      alias :or :any_of

      # Using the existing criteria, find a document by a single id, multiple
      # ids, or using a conditions hash.
      #
      # @example Find a single document by id.
      #   Person.where(:title => "Sir").find(id)
      #
      # @example Find multiple documents by ids.
      #   Person.where(:title => "Sir").find([ id_one, id_two ])
      #
      # @return [ Document, Array<Document> ] The matching document(s).
      #
      # @since 2.0.0.rc.1
      def find(*args)
        id_criteria(*args)
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
        update_selector(attributes, "$in")
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
            else selector ? selector.expand_complex_criteria : {}
          end

          selector.each_pair do |key, value|
            if crit.selector.has_key?(key) && crit.selector[key].respond_to?(:merge!)
              crit.selector[key].merge!(value)
            else
              crit.selector[key] = value
            end
          end
        end
      end
    end
  end
end
