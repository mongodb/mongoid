# encoding: utf-8
module Mongoid #:nodoc:
  module Finders #:nodoc:
    # Find +Documents+ given the conditions.
    #
    # Options:
    #
    # args: A +Hash+ with a conditions key and other options
    #
    # <tt>Person.all(:conditions => { :attribute => "value" })</tt>
    def all(*args)
      find(:all, *args)
    end

    # Returns a count of matching records in the database based on the
    # provided arguments.
    #
    # <tt>Person.count(:first, :conditions => { :attribute => "value" })</tt>
    def count(*args)
      Criteria.translate(self, *args).count
    end

    # Helper to initialize a new +Criteria+ object for this class.
    #
    # Example:
    #
    # <tt>Person.criteria</tt>
    def criteria
      Criteria.new(self)
    end

    # Find a +Document+ in several different ways.
    #
    # If a +String+ is provided, it will be assumed that it is a
    # representation of a Mongo::ObjectID and will attempt to find a single
    # +Document+ based on that id. If a +Symbol+ and +Hash+ is provided then
    # it will attempt to find either a single +Document+ or multiples based
    # on the conditions provided and the first parameter.
    #
    # <tt>Person.find(:first, :conditions => { :attribute => "value" })</tt>
    #
    # <tt>Person.find(:all, :conditions => { :attribute => "value" })</tt>
    #
    # <tt>Person.find(Mongo::ObjectID.new.to_s)</tt>
    def find(*args)
      raise Errors::InvalidOptions.new("Calling Document#find with nil is invalid") if args[0].nil?
      type = args.delete_at(0) if args[0].is_a?(Symbol)
      criteria = Criteria.translate(self, *args)
      case type
      when :first then return criteria.one
      when :last then return criteria.last
      else
        return criteria
      end
    end

    # Find the first +Document+ given the conditions, or creates a new document
    # with the conditions that were supplied
    #
    # Options:
    #
    # args: A +Hash+ of attributes
    #
    # <tt>Person.find_or_create_by(:attribute => "value")</tt>
    def find_or_create_by(attrs = {})
      first(:conditions => attrs) || self.create(attrs)
    end

    # Find the first +Document+ given the conditions, or instantiates a new document
    # with the conditions that were supplied
    #
    # Options:
    #
    # args: A +Hash+ of attributes
    #
    # <tt>Person.find_or_initialize_by(:attribute => "value")</tt>
    def find_or_initialize_by(attrs = {})
      first(:conditions => attrs) || self.new(attrs)
    end

    # Find the first +Document+ given the conditions.
    #
    # Options:
    #
    # args: A +Hash+ with a conditions key and other options
    #
    # <tt>Person.first(:conditions => { :attribute => "value" })</tt>
    def first(*args)
      find(:first, *args)
    end

    # Find the last +Document+ given the conditions.
    #
    # Options:
    #
    # args: A +Hash+ with a conditions key and other options
    #
    # <tt>Person.last(:conditions => { :attribute => "value" })</tt>
    def last(*args)
      find(:last, *args)
    end

    # Convenience method for returning the max value of a field.
    #
    # Options:
    #
    # field: The field to use when calculating the max.
    #
    # Example:
    #
    # <tt>Person.max(:age)</tt>
    #
    # Returns: <tt>Float</tt> max value.
    def max(field)
      Criteria.new(self).max(field)
    end

    # Will execute a +Criteria+ based on the +DynamicFinder+ that gets
    # generated.
    #
    # Options:
    #
    # name: The finder method name
    # args: The arguments to pass to the method.
    #
    # Example:
    #
    # <tt>Person.find_all_by_title_and_age("Sir", 30)</tt>
    # def method_missing(name, *args)
      # dyna = DynamicFinder.new(name, *args)
      # finder, conditions = dyna.finder, dyna.conditions
      # results = find(finder, :conditions => conditions)
      # results ? results : dyna.create(self)
    # end

    # Convenience method for returning the min value of a field.
    #
    # Options:
    #
    # field: The field to use when calculating the min.
    #
    # Example:
    #
    # <tt>Person.min(:age)</tt>
    #
    # Returns: <tt>Float</tt> min value.
    def min(field)
      Criteria.new(self).min(field)
    end

    # Find all documents in paginated fashion given the supplied arguments.
    # If no parameters are passed just default to offset 0 and limit 20.
    #
    # Options:
    #
    # params: A +Hash+ of params to pass to the Criteria API.
    #
    # Example:
    #
    # <tt>Person.paginate(:conditions => { :field => "Test" }, :page => 1,
    # :per_page => 20)</tt>
    #
    # Returns paginated array of docs.
    def paginate(params = {})
      Criteria.translate(self, params).paginate
    end

    # Entry point for creating a new criteria from a Document. This will
    # instantiate a new +Criteria+ object with the supplied select criterion
    # already added to it.
    #
    # Options:
    #
    # args: A list of field names to retrict the returned fields to.
    #
    # Example:
    #
    # <tt>Person.only(:field1, :field2, :field3)</tt>
    #
    # Returns: <tt>Criteria</tt>
    def only(*args)
      Criteria.new(self).only(*args)
    end

    # Convenience method for returning the sum of a specified field for all
    # documents in the database.
    #
    # Options:
    #
    # field: The field to use when calculating the sum.
    #
    # Example:
    #
    # <tt>Person.sum(:age)</tt>
    #
    # Returns: <tt>Float</tt> of the sum.
    def sum(field)
      Criteria.new(self).sum(field)
    end

    # Entry point for creating a new criteria from a Document. This will
    # instantiate a new +Criteria+ object with the supplied select criterion
    # already added to it.
    #
    # Options:
    #
    # selector: A where criteria to initialize.
    #
    # Example:
    #
    # <tt>Person.where(:field1 => "Value")</tt>
    #
    # Returns: <tt>Criteria</tt>
    def where(selector = nil)
      Criteria.new(self).where(selector)
    end

  end
end
