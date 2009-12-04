# encoding: utf-8
module Mongoid #:nodoc:
  class DynamicFinder
    # Regex for standard dynamic finder methods.
    FINDER = /^find_(all_by|last_by|by)_([_a-zA-Z]\w*)$/
    # Regex for finder methods that create objects if nothing found.
    CREATOR = /^find_or_(initialize|create)_by_([_a-zA-Z]\w*)$/

    attr_reader :conditions, :finder

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
      @finder, @args = :first, args
      case method.to_s
      when FINDER
        @finder = :all if $1 == "all_by"
        @finder = :last if $1 == "last_by"
        names = $2
      when CREATOR then
        @creator = ($1 == "initialize") ? :instantiate : :create
        names = $2
      else
        @finder = nil
      end
      @attributes = names && names.split("_and_")
      generate_conditions
    end

    # Will create a new +Document+ based on the type of creator keyword in the
    # method, given the supplied class.
    #
    # Options:
    #
    # klass: The +Document+ class to be instantiated.
    #
    # Example:
    #
    # <tt>finder.create(Person)</tt>
    def create(klass)
      klass.send(@creator, @conditions) if @creator
    end

    protected
    def generate_conditions
      if @attributes
        @conditions = {}.with_indifferent_access
        @attributes.each_with_index do |attr, index|
          attr = "_id" if attr == "id"
          @conditions[attr] = @args[index]
        end
      end
    end

  end
end
