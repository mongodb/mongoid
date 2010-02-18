# encoding: utf-8
module Mongoid #:nodoc:
  module Contexts #:nodoc:
    class Mongo
      include Paging
      attr_reader :criteria

      delegate :klass, :options, :selector, :to => :criteria

      AGGREGATE_REDUCE = "function(obj, prev) { prev.count++; }"
      # Aggregate the context. This will take the internally built selector and options
      # and pass them on to the Ruby driver's +group()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned it will provided a grouping of keys with counts.
      #
      # Example:
      #
      # <tt>context.aggregate</tt>
      #
      # Returns:
      #
      # A +Hash+ with field values as keys, counts as values
      def aggregate
        klass.collection.group(options[:fields], selector, { :count => 0 }, AGGREGATE_REDUCE, true)
      end

      # Get the count of matching documents in the database for the context.
      #
      # Example:
      #
      # <tt>context.count</tt>
      #
      # Returns:
      #
      # An +Integer+ count of documents.
      def count
        @count ||= klass.collection.find(selector, process_options).count
      end

      # Execute the context. This will take the selector and options
      # and pass them on to the Ruby driver's +find()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned new documents of the type of class provided will be instantiated.
      #
      # Example:
      #
      # <tt>mongo.execute</tt>
      #
      # Returns:
      #
      # An enumerable +Cursor+.
      def execute(paginating = false)
        cursor = klass.collection.find(selector, process_options)
        if cursor
          @count = cursor.count if paginating
          cursor
        else
          []
        end
      end

      GROUP_REDUCE = "function(obj, prev) { prev.group.push(obj); }"
      # Groups the context. This will take the internally built selector and options
      # and pass them on to the Ruby driver's +group()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned it will provided a grouping of keys with objects.
      #
      # Example:
      #
      # <tt>context.group</tt>
      #
      # Returns:
      #
      # A +Hash+ with field values as keys, arrays of documents as values.
      def group
        klass.collection.group(
          options[:fields],
          selector,
          { :group => [] },
          GROUP_REDUCE,
          true
        ).collect do |docs|
          docs["group"] = docs["group"].collect do |attrs|
            Mongoid::Factory.build(klass, attrs)
          end
          docs
        end
      end

      # Return documents based on an id search. Will handle if a single id has
      # been passed or mulitple ids.
      #
      # Example:
      #
      #   context.id_criteria([1, 2, 3])
      #
      # Returns:
      #
      # The single or multiple documents.
      def id_criteria(params)
        criteria.id(params)
        result = params.is_a?(Array) ? criteria.entries : one
        if Mongoid.raise_not_found_error
          raise Errors::DocumentNotFound.new(klass, params) if result.blank?
        end
        return result
      end

      # Create the new mongo context. This will execute the queries given the
      # selector and options against the database.
      #
      # Example:
      #
      # <tt>Mongoid::Contexts::Mongo.new(criteria)</tt>
      def initialize(criteria)
        @criteria = criteria
        if criteria.klass.hereditary
          criteria.in(:_type => criteria.klass._types)
        end
      end

      # Return the last result for the +Context+. Essentially does a find_one on
      # the collection with the sorting reversed. If no sorting parameters have
      # been provided it will default to ids.
      #
      # Example:
      #
      # <tt>context.last</tt>
      #
      # Returns:
      #
      # The last document in the collection.
      def last
        opts = process_options
        sorting = opts[:sort]
        sorting = [[:_id, :asc]] unless sorting
        opts[:sort] = sorting.collect { |option| [ option[0], option[1].invert ] }
        attributes = klass.collection.find_one(selector, opts)
        attributes ? Mongoid::Factory.build(klass, attributes) : nil
      end

      MAX_REDUCE = "function(obj, prev) { if (prev.max == 'start') { prev.max = obj.[field]; } " +
        "if (prev.max < obj.[field]) { prev.max = obj.[field]; } }"
      # Return the max value for a field.
      #
      # This will take the internally built selector and options
      # and pass them on to the Ruby driver's +group()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned it will provided a grouping of keys with sums.
      #
      # Example:
      #
      # <tt>context.max(:age)</tt>
      #
      # Returns:
      #
      # A numeric max value.
      def max(field)
        grouped(:max, field.to_s, MAX_REDUCE)
      end

      MIN_REDUCE = "function(obj, prev) { if (prev.min == 'start') { prev.min = obj.[field]; } " +
        "if (prev.min > obj.[field]) { prev.min = obj.[field]; } }"
      # Return the min value for a field.
      #
      # This will take the internally built selector and options
      # and pass them on to the Ruby driver's +group()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned it will provided a grouping of keys with sums.
      #
      # Example:
      #
      # <tt>context.min(:age)</tt>
      #
      # Returns:
      #
      # A numeric minimum value.
      def min(field)
        grouped(:min, field.to_s, MIN_REDUCE)
      end

      # Return the first result for the +Context+.
      #
      # Example:
      #
      # <tt>context.one</tt>
      #
      # Return:
      #
      # The first document in the collection.
      def one
        attributes = klass.collection.find_one(selector, process_options)
        attributes ? Mongoid::Factory.build(klass, attributes) : nil
      end

      alias :first :one

      SUM_REDUCE = "function(obj, prev) { if (prev.sum == 'start') { prev.sum = 0; } prev.sum += obj.[field]; }"
      # Sum the context.
      #
      # This will take the internally built selector and options
      # and pass them on to the Ruby driver's +group()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned it will provided a grouping of keys with sums.
      #
      # Example:
      #
      # <tt>context.sum(:age)</tt>
      #
      # Returns:
      #
      # A numeric value that is the sum.
      def sum(field)
        grouped(:sum, field.to_s, SUM_REDUCE)
      end

      # Common functionality for grouping operations. Currently used by min, max
      # and sum. Will gsub the field name in the supplied reduce function.
      def grouped(start, field, reduce)
        collection = klass.collection.group(
          nil,
          selector,
          { start => "start" },
          reduce.gsub("[field]", field),
          true
        )
        collection.empty? ? nil : collection.first[start.to_s]
      end

      # Filters the field list. If no fields have been supplied, then it will be
      # empty. If fields have been defined then _type will be included as well.
      def process_options
        fields = options[:fields]
        if fields && fields.size > 0 && !fields.include?(:_type)
          fields << :_type
          options[:fields] = fields
        end
        options.dup
      end

    end
  end
end
