# encoding: utf-8
module Mongoid #:nodoc:
  module Finders #:nodoc:

    # Delegate to the criteria methods that are natural for creating a new
    # criteria.
    [ :all_in, :any_in, :asc, :ascending, :avg, :desc, :descending,
      :excludes, :limit, :max, :min, :not_in, :only, :order_by,
      :skip, :sum, :where ].each do |name|
      define_method(name) do |*args|
        criteria.send(name, *args)
      end
    end

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
    # <tt>Person.count(:conditions => { :attribute => "value" })</tt>
    def count(*args)
      Criteria.translate(self, *args).count
    end

    # Returns true if there are on document in database based on the
    # provided arguments.
    #
    # <tt>Person.exists?(:conditions => { :attribute => "value" })</tt>
    def exists?(*args)
      Criteria.translate(self, *args).limit(1).count == 1
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
      find_or(:create, attrs)
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
      find_or(:new, attrs)
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

    protected
    # Find the first object or create/initialize it.
    def find_or(method, attrs = {})
      first(:conditions => attrs) || send(method, attrs)
    end
  end
end
