module Mongoid #:nodoc:
  class Criteria #:nodoc:

    attr_reader :selector, :options

    # Excludes the parameters passed using $ne in the selector.
    def excludes(exclusions = {})
      exclusions.each { |key, value| @selector[key] = { "$ne" => value } }; self
    end

    # Defines criteria for matching any of the supplied parameters, similar to
    # a SQL in statement.
    def in(inclusions)
      inclusions.each { |key, value| @selector[key] = { "$in" => value } }; self
    end

    # Create the new Criteria object. Does not take any params, just
    # initializes the selector and options hashes that will be 
    # eventually passed to the driver.
    def initialize
      @selector, @options = {}, {}
    end

    # Limits the number of results returned by the query, usually used in
    # conjunction with skip() for pagination.
    def limit(value = 20)
      @options[:limit] = value; self
    end

    # The conditions that must prove true on each record in the
    # database in order for them to be a part of the result set.
    # This is a hash that maps to a selector in the driver.
    def matches(selector = {})
      @selector = selector; self
    end

    # Defines a clause that the criteria should ignore.
    def not_in(exclusions)
      exclusions.each { |key, value| @selector[key] = { "$nin" => value } }; self
    end

    # Specifies how to sort this Criteria. Current valid params
    # are: { :field => 1 } or { :field => -1 }
    def order_by(params = {})
      @options[:sort] = params; self
    end

    # Specify what fields to be returned from the database.
    # Similar to a SQL select field1, field2, field3
    def select(*args)
      @options[:fields] = args.flatten; self
    end

    # Skips the supplied number of records, as offset behaves in traditional
    # pagination.
    def skip(value = 0)
      @options[:skip] = value; self
    end

  end
end
