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
      Criteria.translate(*args).count(self)
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
      Criteria.translate(*args).execute(self)
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
      return find(:last, :conditions => {}, :sort => [[:_id, :desc]]) if args.empty?
      return find(:last, *args) unless args.empty?
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
    def method_missing(name, *args)
      dyna = DynamicFinder.new(name, *args)
      finder, conditions = dyna.finder, dyna.conditions
      results = Criteria.translate(finder, :conditions => conditions).execute(self)
      results ? results : dyna.create(self)
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
      Criteria.translate(:all, params).paginate(self)
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
    # <tt>Person.select(:field1, :field2, :field3)</tt>
    #
    # Returns: <tt>Criteria</tt>
    def select(*args)
      Criteria.new(:all, self).select(*args)
    end

  end
end
