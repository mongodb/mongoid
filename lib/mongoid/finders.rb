module Mongoid
  module Finders

    AGGREGATE_REDUCE = "function(obj, prev) { prev.count++; }"
    GROUP_BY_REDUCE = "function(obj, prev) { prev.group.push(obj); }"

    # Find all Documents in several ways.
    # Model.find(:first, :attribute => "value")
    # Model.find(:all, :attribute => "value")
    def find(*args)
      type, selector = args[0], args[1]
      case type
      when :all then find_all(selector[:conditions])
      when :first then find_first(selector[:conditions])
      else find_first(Mongo::ObjectID.from_string(type.to_s))
      end
    end

    # Find a single Document given the passed selector, which is a Hash of attributes that
    # must match the Document in the database exactly.
    def find_first(selector = nil)
      new(collection.find_one(selector))
    end

    # Find all Documents given the passed selector, which is a Hash of attributes that
    # must match the Document in the database exactly.
    def find_all(selector = nil)
      collection.find(selector).collect { |doc| new(doc) }
    end

    # Find all Documents given the supplied criteria, grouped by the fields
    # provided.
    def group_by(fields, selector)
      collection.group(fields, selector, { :group => [] }, GROUP_BY_REDUCE).collect do |docs|
        group!(docs)
      end
    end

    # Find all documents in paginated fashion given the supplied arguments.
    # If no parameters are passed just default to offset 0 and limit 20.
    def paginate(params = {})
      WillPaginate::Collection.create(
        params[:page] || 1,
        params[:per_page] || 20,
        0) do |pager|
          results = collection.find(params[:conditions], { :limit => pager.per_page, :offset => pager.offset })
          pager.total_entries = results.count
          pager.replace(results.collect { |doc| new(doc) })
      end
    end

  end
end
