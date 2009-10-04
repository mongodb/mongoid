module Mongoid
  module Finders

    def self.included(base)
      base.class_eval do
        include InstanceMethods; extend ClassMethods
      end
    end

    module InstanceMethods

      # Get the Mongo::Collection associated with this Document.
      def collection
        self.class.collection
      end

    end

    module ClassMethods

      AGGREGATE_REDUCE = "function(obj, prev) { prev.count++; }"
      GROUP_BY_REDUCE = "function(obj, prev) { prev.group.push(obj); }"

      # Create an association to a parent Document.
      # Get an aggregate count for the supplied group of fields and the
      # selector that is provided.
      def aggregate(fields, params = {})
        selector = params[:conditions]
        collection.group(fields, selector, { :count => 0 }, AGGREGATE_REDUCE)
      end

      # Get the Mongo::Collection associated with this Document.
      def collection
        @collection_name = self.to_s.demodulize.tableize
        @collection ||= Mongoid.database.collection(@collection_name)
      end

      # Find all Documents in several ways.
      # Model.find(:first, :attribute => "value")
      # Model.find(:all, :attribute => "value")
      def find(*args)
        type, params = args[0], args[1]
        case type
        when :all then find_all(params)
        when :first then find_first(params)
        else find_first(Mongo::ObjectID.from_string(type.to_s))
        end
      end

      # Find a single Document given the passed selector, which is a Hash of attributes that
      # must match the Document in the database exactly.
      def find_first(params = {})
        case params
        when Hash then new(collection.find_one(params[:conditions]))
        else new(collection.find_one(params))
        end
      end

      # Find all Documents given the passed selector, which is a Hash of attributes that
      # must match the Document in the database exactly.
      def find_all(params = {})
        selector = params.delete(:conditions)
        collection.find(selector, params).collect { |doc| new(doc) }
      end

      # Find all Documents given the supplied criteria, grouped by the fields
      # provided.
      def group_by(fields, params = {})
        selector = params[:condition]
        collection.group(fields, selector, { :group => [] }, GROUP_BY_REDUCE).collect do |docs|
          docs["group"] = docs["group"].collect { |attrs| new(attrs) }; docs
        end
      end

      # Find all documents in paginated fashion given the supplied arguments.
      # If no parameters are passed just default to offset 0 and limit 20.
      def paginate(params = {})
        selector = params[:conditions]
        WillPaginate::Collection.create(
          params[:page] || 1,
          params[:per_page] || 20,
          0) do |pager|
            results = collection.find(selector, { :sort => (params[:sort] || {}),
                                                  :limit => pager.per_page,
                                                  :offset => pager.offset })
            pager.total_entries = results.count
            pager.replace(results.collect { |doc| new(doc) })
        end
      end

    end

  end
end
