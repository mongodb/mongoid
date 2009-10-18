module Mongoid #:nodoc:
  # The +Criteria+ class is the core object needed in Mongoid to retrieve
  # objects from the database. It is a DSL that essentially sets up the
  # selector and options arguments that get passed on to a <tt>Mongo::Collection</tt>
  # in the Ruby driver. Each method on the +Criteria+ returns self to they
  # can be chained in order to create a readable criterion to be executed
  # against the database.
  #
  # Example setup:
  #
  # <tt>criteria = Criteria.new</tt>
  #
  # <tt>criteria.select(:field => "value").only(:field).skip(20).limit(20)</tt>
  #
  # <tt>criteria.execute</tt>
  class Criteria
    attr_reader :selector, :options, :type

    # Adds a criterion to the +Criteria+ that specifies values that must all
    # be matched in order to return results. Similar to an "in" clause but the
    # underlying conditional logic is an "AND" and not an "OR". The MongoDB
    # conditional operator that will be used is "$all".
    #
    # Options:
    #
    # selections: A +Hash+ where the key is the field name and the value is an 
    # +Array+ of values that must all match.
    #
    # Example:
    #
    # <tt>criteria.all(:field => ["value1", "value2"])</tt>
    #
    # <tt>criteria.all(:field1 => ["value1", "value2"], :field2 => ["value1"])</tt>
    #
    # Returns: <tt>self</tt>
    def all(selections = {})
      selections.each { |key, value| @selector[key] = { "$all" => value } }; self
    end

    # Adds a criterion to the +Criteria+ that specifies values that are not allowed
    # to match any document in the database. The MongoDB conditional operator that
    # will be used is "$ne".
    #
    # Options:
    #
    # excludes: A +Hash+ where the key is the field name and the value is a
    # value that must not be equal to the corresponding field value in the database.
    #
    # Example:
    #
    # <tt>criteria.excludes(:field => "value1")</tt>
    #
    # <tt>criteria.excludes(:field1 => "value1", :field2 => "value1")</tt>
    #
    # Returns: <tt>self</tt>
    def excludes(exclusions = {})
      exclusions.each { |key, value| @selector[key] = { "$ne" => value } }; self
    end

    # Execute the criteria. This will take the internally built selector and options
    # and pass them on to the Ruby driver's +find()+ method on the collection. The
    # collection itself will be retrieved from the class provided, and once the
    # query has returned new documents of the type of class provided will be instantiated.
    #
    # If this is a +Criteria+ to only find the first object, this will return a
    # single object of the type of class provided.
    #
    # If this is a +Criteria+ to find multiple results, will return an +Array+ of
    # objects of the type of class provided.
    def execute(klass)
      return klass.new(klass.collection.find_one(@selector, @options)) if type == :first
      return klass.collection.find(@selector, @options).collect { |doc| klass.new(doc) }
    end

    # Adds a criterion to the +Criteria+ that specifies additional options
    # to be passed to the Ruby driver, in the exact format for the driver.
    #
    # Options:
    #
    # extras: A +Hash+ that gets set to the driver options.
    #
    # Example:
    #
    # <tt>criteria.extras(:limit => 20, :skip => 40)</tt>
    #
    # Returns: <tt>self</tt>
    def extras(extras)
      @options = extras; self
    end

    # Adds a criterion to the +Criteria+ that specifies values where any can
    # be matched in order to return results. This is similar to an SQL "IN"
    # clause. The MongoDB conditional operator that will be used is "$in".
    #
    # Options:
    #
    # inclusions: A +Hash+ where the key is the field name and the value is an
    # +Array+ of values that any can match.
    #
    # Example:
    #
    # <tt>criteria.in(:field => ["value1", "value2"])</tt>
    #
    # <tt>criteria.in(:field1 => ["value1", "value2"], :field2 => ["value1"])</tt>
    #
    # Returns: <tt>self</tt>
    def in(inclusions = {})
      inclusions.each { |key, value| @selector[key] = { "$in" => value } }; self
    end

    # Adds a criterion to the +Criteria+ that specifies an id that must be matched.
    #
    # Options:
    #
    # object_id: A +String+ representation of a <tt>Mongo::ObjectID</tt>
    #
    # Example:
    #
    # <tt>criteria.id("4ab2bc4b8ad548971900005c")</tt>
    #
    # Returns: <tt>self</tt>
    def id(object_id)
      @selector[:_id] = Mongo::ObjectID.from_string(object_id); self
    end

    # Create the new +Criteria+ object. This will initialize the selector
    # and options hashes, as well as the type of criteria.
    #
    # Options:
    #
    # type: One of :all, :first:, or :last
    def initialize(type)
      @selector, @options, @type = {}, {}, type
    end

    # Adds a criterion to the +Criteria+ that specifies the maximum number of
    # results to return. This is mostly used in conjunction with <tt>skip()</tt>
    # to handle paginated results.
    #
    # Options:
    #
    # value: An +Integer+ specifying the max number of results. Defaults to 20.
    #
    # Example:
    #
    # <tt>criteria.limit(100)</tt>
    #
    # Returns: <tt>self</tt>
    def limit(value = 20)
      @options[:limit] = value; self
    end

    # Adds a criterion to the +Criteria+ that specifies values where none
    # should match in order to return results. This is similar to an SQL "NOT IN"
    # clause. The MongoDB conditional operator that will be used is "$nin".
    #
    # Options:
    #
    # exclusions: A +Hash+ where the key is the field name and the value is an
    # +Array+ of values that none can match.
    #
    # Example:
    #
    # <tt>criteria.not_in(:field => ["value1", "value2"])</tt>
    #
    # <tt>criteria.not_in(:field1 => ["value1", "value2"], :field2 => ["value1"])</tt>
    #
    # Returns: <tt>self</tt>
    def not_in(exclusions)
      exclusions.each { |key, value| @selector[key] = { "$nin" => value } }; self
    end

    # Adds a criterion to the +Criteria+ that specifies the sort order of
    # the returned documents in the database. Similar to a SQL "ORDER BY".
    #
    # Options:
    #
    # params: An +Array+ of [field, direction] sorting pairs.
    #
    # Example:
    #
    # <tt>criteria.order_by([[:field1, :asc], [:field2, :desc]])</tt>
    #
    # Returns: <tt>self</tt>
    def order_by(params = [])
      @options[:sort] = params; self
    end

    # Adds a criterion to the +Criteria+ that specifies the fields that will
    # get returned from the Document. Used mainly for list views that do not
    # require all fields to be present. This is similar to SQL "SELECT" values.
    #
    # Options:
    #
    # args: A list of field names to retrict the returned fields to.
    #
    # Example:
    #
    # <tt>criteria.select(:field1, :field2, :field3)</tt>
    #
    # Returns: <tt>self</tt>
    def select(*args)
      @options[:fields] = args.flatten; self
    end

    # Adds a criterion to the +Criteria+ that specifies how many results to skip
    # when returning Documents. This is mostly used in conjunction with 
    # <tt>limit()</tt> to handle paginated results, and is similar to the 
    # traditional "offset" parameter.
    #
    # Options:
    #
    # value: An +Integer+ specifying the number of results to skip. Defaults to 0.
    #
    # Example:
    #
    # <tt>criteria.skip(20)</tt>
    #
    # Returns: <tt>self</tt>
    def skip(value = 0)
      @options[:skip] = value; self
    end

    # Translate the supplied arguments into a +Criteria+ object. 
    # 
    # If the passed in args is a single +String+, then it will 
    # construct an id +Criteria+ from it.
    #
    # If the passed in args are a type and a hash, then it will construct
    # the +Criteria+ with the proper selector, options, and type.
    #
    # Options:
    #
    # args: either a +String+ or a +Symbol+, +Hash combination.
    #
    # Example:
    #
    # <tt>Criteria.translate("4ab2bc4b8ad548971900005c")</tt>
    #
    # <tt>Criteria.translate(:all, :conditions => { :field => "value"}, :limit => 20)</tt>
    #
    # Returns a new +Criteria+ object.
    def self.translate(*args)
      type, params = args[0], args[1] || {}
      return new(:first).id(type.to_s) if type.is_a?(String)
      return new(type).where(params.delete(:conditions)).extras(params)
    end

    # Adds a criterion to the +Criteria+ that specifies values that must
    # be matched in order to return results. This is similar to a SQL "WHERE"
    # clause. This is the actual selector that will be provided to MongoDB, 
    # similar to the Javascript object that is used when performing a find()
    # in the MongoDB console.
    #
    # Options:
    #
    # selectior: A +Hash+ that must match the attributes of the +Document+.
    #
    # Example:
    #
    # <tt>criteria.where(:field1 => "value1", :field2 => 15)</tt>
    #
    # Returns: <tt>self</tt>
    def where(selector = {})
      @selector = selector; self
    end

  end
end
