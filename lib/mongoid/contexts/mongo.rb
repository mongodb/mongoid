# encoding: utf-8
module Mongoid #:nodoc:
  module Contexts #:nodoc:
    class Mongo
      include Ids, Paging
      attr_reader :criteria

      delegate :klass, :options, :selector, :to => :criteria

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
        klass.collection.group(options[:fields], selector, { :count => 0 }, Javascript.aggregate, true)
      end

      # Get the average value for the supplied field.
      #
      # This will take the internally built selector and options
      # and pass them on to the Ruby driver's +group()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned it will provided a grouping of keys with averages.
      #
      # Example:
      #
      # <tt>context.avg(:age)</tt>
      #
      # Returns:
      #
      # A numeric value that is the average.
      def avg(field)
        total = sum(field)
        total ? (total / count) : nil
      end

      # Determine if the context is empty or blank given the criteria. Will
      # perform a quick has_one asking only for the id.
      #
      # Example:
      #
      # <tt>context.blank?</tt>
      def blank?
        klass.collection.find_one(selector, { :fields => [ :_id ] }).nil?
      end

      alias :empty? :blank?

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

      # Gets an array of distinct values for the supplied field across the
      # entire collection or the susbset given the criteria.
      #
      # Example:
      #
      # <tt>context.distinct(:title)</tt>
      def distinct(field)
        klass.collection.distinct(field, selector)
      end

      # Execute the context. This will take the selector and options
      # and pass them on to the Ruby driver's +find()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned new documents of the type of class provided will be instantiated.
      #
      # Example:
      #
      # <tt>context.execute</tt>
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
          Javascript.group
        ).collect do |docs|
          docs["group"] = docs["group"].collect do |attrs|
            Mongoid::Factory.build(klass, attrs)
          end
          docs
        end
      end

      # Create the new mongo context. This will execute the queries given the
      # selector and options against the database.
      #
      # Example:
      #
      # <tt>Mongoid::Contexts::Mongo.new(criteria)</tt>
      def initialize(criteria)
        @criteria = criteria
        if klass.hereditary? && !criteria.selector.keys.include?(:_type)
          criteria.in(:_type => criteria.klass._types)
        end
        criteria.enslave if klass.enslaved?
        criteria.cache if klass.cached?
      end

      # Iterate over each +Document+ in the results. This can take an optional
      # block to pass to each argument in the results.
      #
      # Example:
      #
      # <tt>context.iterate { |doc| p doc }</tt>
      def iterate(&block)
        return caching(&block) if criteria.cached?
        if block_given?
          execute.each { |doc| yield doc }
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
        grouped(:max, field.to_s, Javascript.max)
      end

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
        grouped(:min, field.to_s, Javascript.min)
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

      # Return the first result for the +Context+ and skip it
      # for successive calls.
      #
      # Returns:
      #
      # The first document in the collection.
      def shift
        document = first
        criteria.skip((options[:skip] || 0) + 1)
        document
      end

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
        grouped(:sum, field.to_s, Javascript.sum)
      end

      # Common functionality for grouping operations. Currently used by min, max
      # and sum. Will gsub the field name in the supplied reduce function.
      def grouped(start, field, reduce)
        collection = klass.collection.group(
          nil,
          selector,
          { start => "start" },
          reduce.gsub("[field]", field)
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

      protected

      # Iterate over each +Document+ in the results and cache the collection.
      def caching(&block)
        if defined? @collection
          @collection.each(&block)
        else
          @collection = []
          execute.each do |doc|
            @collection << doc
            yield doc if block_given?
          end
        end
      end
    end
  end
end
