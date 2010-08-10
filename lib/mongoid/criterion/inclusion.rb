# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Inclusion
      # Adds a criterion to the +Criteria+ that specifies values that must all
      # be matched in order to return results. Similar to an "in" clause but the
      # underlying conditional logic is an "AND" and not an "OR". The MongoDB
      # conditional operator that will be used is "$all".
      #
      # Options:
      #
      # attributes: A +Hash+ where the key is the field name and the value is an
      # +Array+ of values that must all match.
      #
      # Example:
      #
      # <tt>criteria.all(:field => ["value1", "value2"])</tt>
      #
      # <tt>criteria.all(:field1 => ["value1", "value2"], :field2 => ["value1"])</tt>
      #
      # Returns: <tt>self</tt>
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
      # Options:
      #
      # selectior: A +Hash+ that must match the attributes of the +Document+.
      #
      # Example:
      #
      # <tt>criteria.and(:field1 => "value1", :field2 => 15)</tt>
      #
      # Returns: <tt>self</tt>
      def and(selector = nil)
        where(selector)
      end

      # Adds a criterion to the +Criteria+ that specifies a set of expressions
      # to match if any of them return true. This is a $or query in MongoDB and
      # is similar to a SQL OR. This is named #any_of and aliased "or" for
      # readability.
      #
      # Options:
      #
      # selector: Multiple +Hash+ expressions that any can match.
      #
      # Example:
      #
      # <tt>criteria.any_of({ :field1 => "value" }, { :field2 => "value2" })</tt>
      #
      # Returns: <tt>self</tt>
      def any_of(*args)
        criterion = @selector["$or"] || []
        expanded = args.collect(&:expand_complex_criteria)
        @selector["$or"] = criterion.concat(expanded)
        self
      end
      alias :or :any_of

      # Adds a criterion to the +Criteria+ that specifies values where any can
      # be matched in order to return results. This is similar to an SQL "IN"
      # clause. The MongoDB conditional operator that will be used is "$in".
      #
      # Options:
      #
      # attributes: A +Hash+ where the key is the field name and the value is an
      # +Array+ of values that any can match.
      #
      # Example:
      #
      # <tt>criteria.in(:field => ["value1", "value2"])</tt>
      #
      # <tt>criteria.in(:field1 => ["value1", "value2"], :field2 => ["value1"])</tt>
      #
      # Returns: <tt>self</tt>
      def in(attributes = {})
        update_selector(attributes, "$in")
      end
      alias :any_in :in

      # Adds a criterion to the +Criteria+ that specifies values to do
      # geospacial searches by. The field must be indexed with the "2d" option.
      #
      # Options:
      #
      # attributes: A +Hash+ where the keys are the field names and the values are
      # +Arrays+ of [latitude, longitude] pairs.
      #
      # Example:
      #
      # <tt>criteria.near(:field1 => [30, -44])</tt>
      #
      # Returns: <tt>self</tt>
      def near(attributes = {})
        update_selector(attributes, "$near")
      end

      # Adds a criterion to the +Criteria+ that specifies values that must
      # be matched in order to return results. This is similar to a SQL "WHERE"
      # clause. This is the actual selector that will be provided to MongoDB,
      # similar to the Javascript object that is used when performing a find()
      # in the MongoDB console.
      #
      # Options:
      #
      # selector: A +Hash+ that must match the attributes of the +Document+.
      #
      # Example:
      #
      # <tt>criteria.where(:field1 => "value1", :field2 => 15)</tt>
      #
      # Returns: <tt>self</tt>
      def where(selector = nil)
        selector = case selector
          when String then {"$where" => selector}
          else selector ? selector.expand_complex_criteria : {}
        end

        selector.each_pair do |key, value|
          if @selector.has_key?(key) && @selector[key].respond_to?(:merge!)
            @selector[key].merge!(value)
          else
            @selector[key] = value
          end
        end

        self
      end
    end
  end
end
