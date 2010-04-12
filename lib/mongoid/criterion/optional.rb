# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Optional
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
      # object_id: A +String+ representation of a <tt>BSON::ObjectID</tt>
      #
      # Example:
      #
      # <tt>criteria.id("4ab2bc4b8ad548971900005c")</tt>
      #
      # Returns: <tt>self</tt>
      def id(*args)
        (args.flatten.size > 1) ? self.in(:_id => args.flatten) : (@selector[:_id] = args.first)
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
      def order_by(params = [])
        @options[:sort] = params; self
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
    end
  end
end
