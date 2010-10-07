# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Optional

      def using_default_sort?
        @use_default_sort = true if @use_default_sort.nil? # TODO: move initialization elsewhere
        return @use_default_sort
      end

      def remove_default_sort
        @options[:sort] = nil if using_default_sort?
        @use_default_sort = false
      end

      # Adds fields to be sorted in ascending order. Will add them in the order
      # they were passed into the method.
      #
      # Example:
      #
      # <tt>criteria.ascending(:title, :dob)</tt>
      def ascending(*fields)
        remove_default_sort

        @options[:sort] = [] unless @options[:sort] || fields.first.nil?
        fields.flatten.each { |field| @options[:sort] << [ field, :asc ] }
        self
      end

      alias :asc :ascending

      # Tells the criteria that the cursor that gets returned needs to be
      # cached. This is so multiple iterations don't hit the database multiple
      # times, however this is not advisable when working with large data sets
      # as the entire results will get stored in memory.
      #
      # Example:
      #
      # <tt>criteria.cache</tt>
      def cache
        @options.merge!(:cache => true); self
      end

      # Will return true if the cache option has been set.
      #
      # Example:
      #
      # <tt>criteria.cached?</tt>
      def cached?
        @options[:cache] == true
      end

      # Adds fields to be sorted in descending order. Will add them in the order
      # they were passed into the method.
      #
      # Example:
      #
      # <tt>criteria.descending(:title, :dob)</tt>
      def descending(*fields)
        remove_default_sort

        @options[:sort] = [] unless @options[:sort] || fields.first.nil?
        fields.flatten.each { |field| @options[:sort] << [ field, :desc ] }
        self
      end

      alias :desc :descending

      # Flags the criteria to execute against a read-only slave in the pool
      # instead of master.
      #
      # Example:
      #
      # <tt>criteria.enslave</tt>
      def enslave
        @options.merge!(:enslave => true); self
      end

      # Will return true if the criteria is enslaved.
      #
      # Example:
      #
      # <tt>criteria.enslaved?</tt>
      def enslaved?
        @options[:enslave] == true
      end

      # Adds a criterion to the +Criteria+ that specifies additional options
      # to be passed to the Ruby driver, in the exact format for the driver.
      #
      # Options:
      #
      # extras: A +Hash+ that gets set to the driver options.
      #
      # Example:
      #
      # <tt>criteria.extras(:limit => 20, :skip => 40)</tt>
      #
      # Returns: <tt>self</tt>
      def extras(extras)
        @options.merge!(extras); filter_options; self
      end

      # Adds a criterion to the +Criteria+ that specifies an id that must be matched.
      #
      # Options:
      #
      # object_id: A single id or an array of ids in +String+ or <tt>BSON::ObjectId</tt> format
      #
      # Example:
      #
      # <tt>criteria.id("4ab2bc4b8ad548971900005c")</tt>
      # <tt>criteria.id(["4ab2bc4b8ad548971900005c", "4c454e7ebf4b98032d000001"])</tt>
      #
      # Returns: <tt>self</tt>
      def id(*ids)
        ids.flatten!
        if ids.size > 1
          self.in(
            :_id => ::BSON::ObjectId.cast!(@klass, ids, @klass.primary_key.nil?)
          )
        else
          @selector[:_id] =
            ::BSON::ObjectId.cast!(@klass, ids.first, @klass.primary_key.nil?)
        end
        self
      end

      # Adds a criterion to the +Criteria+ that specifies the maximum number of
      # results to return. This is mostly used in conjunction with <tt>skip()</tt>
      # to handle paginated results.
      #
      # Options:
      #
      # value: An +Integer+ specifying the max number of results. Defaults to 20.
      #
      # Example:
      #
      # <tt>criteria.limit(100)</tt>
      #
      # Returns: <tt>self</tt>
      def limit(value = 20)
        @options[:limit] = value; self
      end

      # Returns the offset option. If a per_page option is in the list then it
      # will replace it with a skip parameter and return the same value. Defaults
      # to 20 if nothing was provided.
      def offset(*args)
        args.size > 0 ? skip(args.first) : @options[:skip]
      end

      # Adds a criterion to the +Criteria+ that specifies the sort order of
      # the returned documents in the database. Similar to a SQL "ORDER BY".
      #
      # Options:
      #
      # params: An +Array+ of [field, direction] sorting pairs.
      #
      # Example:
      #
      # <tt>criteria.order_by([[:field1, :asc], [:field2, :desc]])</tt>
      #
      # Returns: <tt>self</tt>
      def order_by(*args)
        remove_default_sort
        set_order_by(*args)
      end

      def set_order_by(*args)
        @options[:sort] = [] unless @options[:sort] || args.first.nil?
        arguments = args.first
        case arguments
        when Hash
          arguments.each do |field, direction|
            @options[:sort] << [ field, direction ]
          end
        when Array
          @options[:sort].concat(arguments)
        when Complex
          args.flatten.each do |complex|
            @options[:sort] << [ complex.key, complex.operator.to_sym ]
          end
        end; self
      end

      # Adds a criterion to the +Criteria+ that specifies how many results to skip
      # when returning Documents. This is mostly used in conjunction with
      # <tt>limit()</tt> to handle paginated results, and is similar to the
      # traditional "offset" parameter.
      #
      # Options:
      #
      # value: An +Integer+ specifying the number of results to skip. Defaults to 0.
      #
      # Example:
      #
      # <tt>criteria.skip(20)</tt>
      #
      # Returns: <tt>self</tt>
      def skip(value = 0)
        @options[:skip] = value; self
      end

      # Adds a criterion to the +Criteria+ that specifies a type or an Array of
      # type that must be matched.
      #
      # Options:
      #
      # types : An +Array+ of types of a +String+ representing the Type of you search
      #
      # Example:
      #
      # <tt>criteria.type('Browser')</tt>
      # <tt>criteria.type(['Firefox', 'Browser'])</tt>
      #
      # Returns: <tt>self</tt>
      def type(types)
        types = [types] unless types.is_a?(Array)
        self.in(:_type => types)
      end

    end
  end
end
