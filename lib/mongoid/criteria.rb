module Mongoid #:nodoc:
  class Criteria #:nodoc:
    attr_reader :selector, :options, :type

    # Supply a hash of arrays for field values that must match every single
    # element in the array.
    def all(selections = {})
      selections.each { |key, value| @selector[key] = { "$all" => value } }; self
    end

    # Excludes the parameters passed using $ne in the selector.
    def excludes(exclusions = {})
      exclusions.each { |key, value| @selector[key] = { "$ne" => value } }; self
    end

    # Execute the criteria, which will retrieve the results from
    # the collection.
    def execute(klass)
      return klass.new(klass.collection.find_one(@selector, @options)) if type == :first
      return klass.collection.find(@selector, @options).collect { |doc| klass.new(doc) }
    end

    # Defines criteria for matching any of the supplied parameters, similar to
    # a SQL in statement.
    def in(inclusions = {})
      inclusions.each { |key, value| @selector[key] = { "$in" => value } }; self
    end

    # Adds an _id criteria to the selector.
    def id(object_id)
      @selector[:_id] = Mongo::ObjectID.from_string(object_id); self
    end

    # Create the new Criteria object. Does not take any params, just
    # initializes the selector and options hashes that will be 
    # eventually passed to the driver.
    def initialize(type)
      @selector, @options, @type = {}, {}, type
    end

    # Limits the number of results returned by the query, usually used in
    # conjunction with skip() for pagination.
    def limit(value = 20)
      @options[:limit] = value; self
    end

    # The conditions that must prove true on each record in the
    # database in order for them to be a part of the result set.
    # This is a hash that maps to a selector in the driver.
    def select(selector = {})
      @selector = selector; self
    end

    # Defines a clause that the criteria should ignore.
    def not_in(exclusions)
      exclusions.each { |key, value| @selector[key] = { "$nin" => value } }; self
    end

    # Define extras for the criteria.
    def extras(extras)
      @options = extras; self
    end

    # Specifies how to sort this Criteria. Current valid params
    # are: { :field => 1 } or { :field => -1 }
    def order_by(params = {})
      @options[:sort] = params; self
    end

    # Specify what fields to be returned from the database.
    # Similar to a SQL select field1, field2, field3
    def only(*args)
      @options[:fields] = args.flatten; self
    end

    # Skips the supplied number of records, as offset behaves in traditional
    # pagination.
    def skip(value = 0)
      @options[:skip] = value; self
    end

    # Translate the supplied arguments into a criteria object.
    def self.translate(*args)
      type, params = args[0], args[1] || {}
      return new(:first).id(type.to_s) if type.is_a?(String)
      return new(type).select(params.delete(:conditions)).extras(params)
    end

  end
end
