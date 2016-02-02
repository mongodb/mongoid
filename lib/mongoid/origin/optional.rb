# encoding: utf-8
module Origin

  # The optional module includes all behaviour that has to do with extra
  # options surrounding queries, like skip, limit, sorting, etc.
  module Optional
    extend Macroable

    # @attribute [rw] options The query options.
    attr_accessor :options

    # Add ascending sorting options for all the provided fields.
    #
    # @example Add ascending sorting.
    #   optional.ascending(:first_name, :last_name)
    #
    # @param [ Array<Symbol> ] fields The fields to sort.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def ascending(*fields)
      sort_with_list(*fields, 1)
    end
    alias :asc :ascending
    key :asc, :override, 1
    key :ascending, :override, 1

    # Adds the option for telling MongoDB how many documents to retrieve in
    # it's batching.
    #
    # @example Apply the batch size options.
    #   optional.batch_size(500)
    #
    # @param [ Integer ] value The batch size.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def batch_size(value = nil)
      option(value) { |options| options.store(:batch_size, value) }
    end

    # Add descending sorting options for all the provided fields.
    #
    # @example Add descending sorting.
    #   optional.descending(:first_name, :last_name)
    #
    # @param [ Array<Symbol> ] fields The fields to sort.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def descending(*fields)
      sort_with_list(*fields, -1)
    end
    alias :desc :descending
    key :desc, :override, -1
    key :descending, :override, -1

    # Add an index hint to the query options.
    #
    # @example Add an index hint.
    #   optional.hint("$natural" => 1)
    #
    # @param [ Hash ] value The index hint.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def hint(value = nil)
      option(value) { |options| options.store(:hint, value) }
    end

    # Add the number of documents to limit in the returned results.
    #
    # @example Limit the number of returned documents.
    #   optional.limit(20)
    #
    # @param [ Integer ] value The number of documents to return.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def limit(value = nil)
      option(value) do |options, query|
        val = value.to_i
        options.store(:limit, val)
        query.pipeline.push("$limit" => val) if aggregating?
      end
    end

    # Adds the option to limit the number of documents scanned in the
    # collection.
    #
    # @example Add the max scan limit.
    #   optional.max_scan(1000)
    #
    # @param [ Integer ] value The max number of documents to scan.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def max_scan(value = nil)
      option(value) { |options| options.store(:max_scan, value) }
    end

    # Tell the query not to timeout.
    #
    # @example Tell the query not to timeout.
    #   optional.no_timeout
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def no_timeout
      clone.tap { |query| query.options.store(:timeout, false) }
    end

    # Limits the results to only contain the fields provided.
    #
    # @example Limit the results to the provided fields.
    #   optional.only(:name, :dob)
    #
    # @param [ Array<Symbol> ] args The fields to return.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def only(*args)
      args = args.flatten
      option(*args) do |options|
        options.store(
          :fields, args.inject(options[:fields] || {}){ |sub, field| sub.tap { sub[field] = 1 }}
        )
      end
    end

    # Adds sorting criterion to the options.
    #
    # @example Add sorting options via a hash with integer directions.
    #   optional.order_by(name: 1, dob: -1)
    #
    # @example Add sorting options via a hash with symbol directions.
    #   optional.order_by(name: :asc, dob: :desc)
    #
    # @example Add sorting options via a hash with string directions.
    #   optional.order_by(name: "asc", dob: "desc")
    #
    # @example Add sorting options via an array with integer directions.
    #   optional.order_by([[ name, 1 ], [ dob, -1 ]])
    #
    # @example Add sorting options via an array with symbol directions.
    #   optional.order_by([[ name, :asc ], [ dob, :desc ]])
    #
    # @example Add sorting options via an array with string directions.
    #   optional.order_by([[ name, "asc" ], [ dob, "desc" ]])
    #
    # @example Add sorting options with keys.
    #   optional.order_by(:name.asc, :dob.desc)
    #
    # @example Add sorting options via a string.
    #   optional.order_by("name ASC, dob DESC")
    #
    # @param [ Array, Hash, String ] spec The sorting specification.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def order_by(*spec)
      option(spec) do |options, query|
        spec.compact.each do |criterion|
          criterion.__sort_option__.each_pair do |field, direction|
            add_sort_option(options, field, direction)
          end
          query.pipeline.push("$sort" => options[:sort]) if aggregating?
        end
      end
    end
    alias :order :order_by

    # Instead of merging the order criteria, use this method to completely
    # replace the existing ordering with the provided.
    #
    # @example Replace the ordering.
    #   optional.reorder(name: :asc)
    #
    # @param [ Array, Hash, String ] spec The sorting specification.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 2.1.0
    def reorder(*spec)
      options.delete(:sort)
      order_by(*spec)
    end

    # Add the number of documents to skip.
    #
    # @example Add the number to skip.
    #   optional.skip(100)
    #
    # @param [ Integer ] value The number to skip.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def skip(value = nil)
      option(value) do |options, query|
        val = value.to_i
        options.store(:skip, val)
        query.pipeline.push("$skip" => val) if aggregating?
      end
    end
    alias :offset :skip

    # Limit the returned results via slicing embedded arrays.
    #
    # @example Slice the returned results.
    #   optional.slice(aliases: [ 0, 5 ])
    #
    # @param [ Hash ] criterion The slice options.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def slice(criterion = nil)
      option(criterion) do |options|
        options.__union__(
          fields: criterion.inject({}) do |option, (field, val)|
            option.tap { |opt| opt.store(field, { "$slice" => val }) }
          end
        )
      end
    end

    # Tell the query to operate in snapshot mode.
    #
    # @example Add the snapshot option.
    #   optional.snapshot
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def snapshot
      clone.tap do |query|
        query.options.store(:snapshot, true)
      end
    end

    # Limits the results to only contain the fields not provided.
    #
    # @example Limit the results to the fields not provided.
    #   optional.without(:name, :dob)
    #
    # @param [ Array<Symbol> ] args The fields to ignore.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def without(*args)
      args = args.flatten
      option(*args) do |options|
        options.store(
          :fields, args.inject(options[:fields] || {}){ |sub, field| sub.tap { sub[field] = 0 }}
        )
      end
    end

    # Associate a comment with the query.
    #
    # @example Add a comment.
    #   optional.comment('slow query')
    #
    # @note Set profilingLevel to 2 and the comment will be logged in the profile
    #   collection along with the query.
    #
    # @param [ String ] comment The comment to be associated with the query.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 2.2.0
    def comment(comment = nil)
      clone.tap do |query|
        query.options.store(:comment, comment)
      end
    end

    # Set the cursor type.
    #
    # @example Set the cursor type.
    #   optional.cursor_type(:tailable)
    #   optional.cursor_type(:tailable_await)
    #
    # @note The cursor can be type :tailable or :tailable_await.
    #
    # @param [ Symbol ] type The type of cursor to create.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 2.2.0
    def cursor_type(type)
      clone.tap { |query| query.options.store(:cursor_type, type) }
    end

    private

    # Add a single sort option.
    #
    # @api private
    #
    # @example Add a single sort option.
    #   optional.add_sort_option({}, :name, 1)
    #
    # @param [ Hash ] options The options.
    # @param [ String ] field The field name.
    # @param [ Integer ] direction The sort direction.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def add_sort_option(options, field, direction)
      if driver == :mongo1x
        sorting = (options[:sort] || []).dup
        sorting.push([ field, direction ])
        options.store(:sort, sorting)
      else
        sorting = (options[:sort] || {}).dup
        sorting[field] = direction
        options.store(:sort, sorting)
      end
    end

    # Take the provided criterion and store it as an option in the query
    # options.
    #
    # @api private
    #
    # @example Store the option.
    #   optional.option({ skip: 10 })
    #
    # @param [ Array ] args The options.
    #
    # @return [ Queryable ] The cloned queryable.
    #
    # @since 1.0.0
    def option(*args)
      clone.tap do |query|
        unless args.compact.empty?
          yield(query.options, query)
        end
      end
    end

    # Add multiple sort options at once.
    #
    # @api private
    #
    # @example Add multiple sort options.
    #   optional.sort_with_list(:name, :dob, 1)
    #
    # @param [ Array<String> ] fields The field names.
    # @param [ Integer ] direction The sort direction.
    #
    # @return [ Optional ] The cloned optional.
    #
    # @since 1.0.0
    def sort_with_list(*fields, direction)
      option(fields) do |options, query|
        fields.flatten.compact.each do |field|
          add_sort_option(options, field, direction)
        end
        query.pipeline.push("$sort" => options[:sort]) if aggregating?
      end
    end

    class << self

      # Get the methods on the optional that can be forwarded to from a model.
      #
      # @example Get the forwardable methods.
      #   Optional.forwardables
      #
      # @return [ Array<Symbol> ] The names of the forwardable methods.
      #
      # @since 1.0.0
      def forwardables
        public_instance_methods(false) - [ :options, :options= ]
      end
    end
  end
end
