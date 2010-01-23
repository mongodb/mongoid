# encoding: utf-8
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
  # <tt>criteria.only(:field).where(:field => "value").skip(20).limit(20)</tt>
  #
  # <tt>criteria.execute</tt>
  class Criteria
    include Enumerable

    attr_accessor :documents
    attr_reader :klass, :options, :selector

    delegate \
      :aggregate,
      :count,
      :execute,
      :first,
      :group,
      :last,
      :max,
      :min,
      :one,
      :page,
      :paginate,
      :per_page,
      :sum, :to => :context

    # Concatinate the criteria with another enumerable. If the other is a
    # +Criteria+ then it needs to get the collection from it.
    def +(other)
      entries + (other.is_a?(Criteria) ? other.entries : other)
    end

    # Returns the difference between the criteria and another enumerable. If
    # the other is a +Criteria+ then it needs to get the collection from it.
    def -(other)
      entries - (other.is_a?(Criteria) ? other.entries : other)
    end

    # Returns true if the supplied +Enumerable+ or +Criteria+ is equal to the results
    # of this +Criteria+ or the criteria itself.
    #
    # This will force a database load when called if an enumerable is passed.
    #
    # Options:
    #
    # other: The other +Enumerable+ or +Criteria+ to compare to.
    def ==(other)
      case other
      when Criteria
        self.selector == other.selector && self.options == other.options
      when Enumerable
        @collection ||= execute
        return (@collection == other)
      else
        return false
      end
    end

    # Adds a criterion to the +Criteria+ that specifies values that must all
    # be matched in order to return results. Similar to an "in" clause but the
    # underlying conditional logic is an "AND" and not an "OR". The MongoDB
    # conditional operator that will be used is "$all".
    #
    # Options:
    #
    # attributes: A +Hash+ where the key is the field name and the value is an
    # +Array+ of values that must all match.
    #
    # Example:
    #
    # <tt>criteria.all(:field => ["value1", "value2"])</tt>
    #
    # <tt>criteria.all(:field1 => ["value1", "value2"], :field2 => ["value1"])</tt>
    #
    # Returns: <tt>self</tt>
    def all(attributes = {})
      update_selector(attributes, "$all")
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
    # <tt>criteria.and(:field1 => "value1", :field2 => 15)</tt>
    #
    # Returns: <tt>self</tt>
    def and(selector = nil)
      where(selector)
    end

    # Return or create the context in which this criteria should be executed.
    #
    # This will return an Enumerable context if the class is embedded,
    # otherwise it will return a Mongo context for root classes.
    def context
      @context ||= determine_context
    end

    # Merges the supplied argument hash into a single criteria
    #
    # Options:
    #
    # criteria_conditions: Hash of criteria keys, and parameter values
    #
    # Example:
    #
    # <tt>criteria.fuse(:where => { :field => "value"}, :limit => 20)</tt>
    #
    # Returns <tt>self</tt>
    def fuse(criteria_conditions = {})
      criteria_conditions.inject(self) do |criteria, (key, value)|
        criteria.send(key, value)
      end
    end

    # Iterate over each +Document+ in the results. This can take an optional
    # block to pass to each argument in the results.
    #
    # Example:
    #
    # <tt>criteria.each { |doc| p doc }</tt>
    def each(&block)
      @collection ||= execute
      block_given? ? @collection.each { |doc| yield doc } : self
    end

    # Adds a criterion to the +Criteria+ that specifies values that are not allowed
    # to match any document in the database. The MongoDB conditional operator that
    # will be used is "$ne".
    #
    # Options:
    #
    # attributes: A +Hash+ where the key is the field name and the value is a
    # value that must not be equal to the corresponding field value in the database.
    #
    # Example:
    #
    # <tt>criteria.excludes(:field => "value1")</tt>
    #
    # <tt>criteria.excludes(:field1 => "value1", :field2 => "value1")</tt>
    #
    # Returns: <tt>self</tt>
    def excludes(attributes = {})
      update_selector(attributes, "$ne")
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
      @options = extras; filter_options; self
    end

    # Adds a criterion to the +Criteria+ that specifies values where any can
    # be matched in order to return results. This is similar to an SQL "IN"
    # clause. The MongoDB conditional operator that will be used is "$in".
    #
    # Options:
    #
    # attributes: A +Hash+ where the key is the field name and the value is an
    # +Array+ of values that any can match.
    #
    # Example:
    #
    # <tt>criteria.in(:field => ["value1", "value2"])</tt>
    #
    # <tt>criteria.in(:field1 => ["value1", "value2"], :field2 => ["value1"])</tt>
    #
    # Returns: <tt>self</tt>
    def in(attributes = {})
      update_selector(attributes, "$in")
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
    def id(*args)
      (args.flatten.size > 1) ? self.in(:_id => args.flatten) : (@selector[:_id] = *args)
      self
    end

    # Create the new +Criteria+ object. This will initialize the selector
    # and options hashes, as well as the type of criteria.
    #
    # Options:
    #
    # type: One of :all, :first:, or :last
    # klass: The class to execute on.
    def initialize(klass)
      @selector, @options, @klass, @documents = {}, {}, klass, []
      if klass.hereditary
        @selector = { :_type => { "$in" => klass._types } }
        @hereditary = true
      end
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

    # Merges another object into this +Criteria+. The other object may be a
    # +Criteria+ or a +Hash+. This is used to combine multiple scopes together,
    # where a chained scope situation may be desired.
    #
    # Options:
    #
    # other: The +Criteria+ or +Hash+ to merge with.
    #
    # Example:
    #
    # <tt>criteria.merge({ :conditions => { :title => "Sir" } })</tt>
    def merge(other)
      @selector.update(other.selector)
      @options.update(other.options)
      @documents = other.documents
    end

    # Used for chaining +Criteria+ scopes together in the for of class methods
    # on the +Document+ the criteria is for.
    #
    # Options:
    #
    # name: The name of the class method on the +Document+ to chain.
    # args: The arguments passed to the method.
    #
    # Example:
    #
    #   class Person
    #     include Mongoid::Document
    #     field :title
    #     field :terms, :type => Boolean, :default => false
    #
    #     class << self
    #       def knights
    #         all(:conditions => { :title => "Sir" })
    #       end
    #
    #       def accepted
    #         all(:conditions => { :terms => true })
    #       end
    #     end
    #   end
    #
    #   Person.accepted.knights #returns a merged criteria of the 2 scopes.
    #
    # Returns: <tt>Criteria</tt>
    def method_missing(name, *args)
      if @klass.respond_to?(name)
        new_scope = @klass.send(name)
        new_scope.merge(self)
        return new_scope
      else
        return entries.send(name, *args)
      end
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

    # Returns the offset option. If a per_page option is in the list then it
    # will replace it with a skip parameter and return the same value. Defaults
    # to 20 if nothing was provided.
    def offset
      @options[:skip]
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
    # <tt>criteria.only(:field1, :field2, :field3)</tt>
    #
    # Returns: <tt>self</tt>
    def only(*args)
      @options[:fields] = args.flatten if args.any?; self
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

    # Returns the selector and options as a +Hash+ that would be passed to a
    # scope for use with named scopes.
    def scoped
      { :where => @selector }.merge(@options)
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

    alias :to_ary :to_a

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
    # <tt>Criteria.translate(Person, "4ab2bc4b8ad548971900005c")</tt>
    #
    # <tt>Criteria.translate(Person, :conditions => { :field => "value"}, :limit => 20)</tt>
    #
    # Returns a new +Criteria+ object.
    def self.translate(*args)
      klass = args[0]
      params = args[1] || {}
      unless params.is_a?(Hash)
        return id_criteria(klass, params)
      end
      return new(klass).where(params.delete(:conditions) || {}).extras(params)
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
    def where(selector = nil)
      case selector
      when String
        @selector.update("$where" => selector)
      else
        @selector.update(selector ? selector.expand_complex_criteria : {})
      end
      self
    end

    protected
    # Determines the context to be used for this criteria.
    def determine_context
      if @klass.embedded
        return Contexts::Enumerable.new(@selector, @options, @documents)
      end
      Contexts::Mongo.new(@selector, @options, @klass)
    end

    # Filters the unused options out of the options +Hash+. Currently this
    # takes into account the "page" and "per_page" options that would be passed
    # in if using will_paginate.
    def filter_options
      page_num = @options.delete(:page)
      per_page_num = @options.delete(:per_page)
      if (page_num || per_page_num)
        @options[:limit] = limits = (per_page_num || 20).to_i
        @options[:skip] = (page_num || 1).to_i * limits - limits
      end
    end

    # Update the selector setting the operator on the value for each key in the
    # supplied attributes +Hash+.
    def update_selector(attributes, operator)
      attributes.each { |key, value| @selector[key] = { operator => value } }; self
    end

    class << self
      # Return a criteria or single document based on an id search.
      def id_criteria(klass, params)
        criteria = new(klass).id(params)
        result = params.is_a?(String) ? criteria.one : criteria.entries
        if Mongoid.raise_not_found_error
          raise Errors::DocumentNotFound.new(klass, params) if result.blank?
        end
        return result
      end
    end
  end
end
