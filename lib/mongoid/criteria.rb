module Mongoid #:nodoc:
  class Criteria #:nodoc:

    attr_reader :selector, :options

    # Create the new Criteria object. Does not take any params, just
    # initializes the selector and options hashes that will be 
    # eventually passed to the driver.
    def initialize
      @selector, @options = {}, {}
    end

    # Specify what fields to be returned from the database.
    # Similar to a SQL select field1, field2, field3
    def select(*args)
      @options[:fields] = args.flatten; self
    end

    # The conditions that must prove true on each record in the
    # database in order for them to be a part of the result set.
    # This is a hash that maps to a selector in the driver.
    def where(selector = {})
      @selector = selector; self
    end
  end
end