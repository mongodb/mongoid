module Mongoloid
  class Paginator

    attr_reader :limit, :offset

    # Create the new Paginator with the supplied options. 
    # * Will default to offset 0 if no page defined in the options.
    # * Will default to limit 20 if no per_page defined in the options.
    def initialize(options = {})
      @limit = options[:per_page] || 20
      @offset = options[:page] ? (options[:page] - 1) * @limit : 0
    end

    # Generate the options needed for returning the correct
    # results given the supplied parameters
    def options
      { :limit => @limit, :offset => @offset }
    end

  end
end