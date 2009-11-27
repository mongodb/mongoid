module Mongoid #:nodoc:
  class DynamicFinder
    # Regex for standard dynamic finder methods.
    FINDER = /^find_(all_by|last_by|by)_([_a-zA-Z]\w*)$/
    # Regex for finder methods ending in a bang.
    BANG_FINDER = /^find_by_([_a-zA-Z]\w*)\!$/
    # Regex for finder methods that create objects if nothing found.
    CREATOR = /^find_or_(initialize|create)_by_([_a-zA-Z]\w*)$/

    attr_reader :attributes, :bang, :creator, :finder

    # Creates a new DynamicFinder given the supplied method name. This parses
    # the name and sets up the appropriate finder type and attribute names in
    # order to perform the search.
    #
    # Options:
    #
    # method: The name of the dynamic finder method.
    #
    # Example:
    #
    # <tt>DynamicFinder.new(:find_by_title_and_age)</tt>
    def initialize(method, *args)
      @finder, @bang, @args = :first, false, args
      case method.to_s
      when FINDER
        @finder = :all if $1 == "all_by"
        @finder = :last if $1 == "last_by"
        names = $2
      when BANG_FINDER then
        @bang = true
        names = $1
      when CREATOR then
        @creator = ($1 == "initialize") ? :new : :create
        names = $2
      else
        @finder = nil
      end
      @attributes = names && names.split("_and_")
    end

    # Provides a conditions +Hash+ that will be passed onto the +Criteria+ API
    # in order to execute the search. This is built off the attributes derived
    # from the method name and the args passed into the constructor.
    #
    # Example:
    #
    #   finder = DynamicFinder.new(:find_by_id, "5")
    #   finder.conditions # { :id => "5" }
    def conditions
      conds = {}.with_indifferent_access
      @attributes.each_with_index do |attr, index|
        attr = "_id" if attr == "id"
        conds[attr] = @args[index]
      end
      conds
    end

  end
end
