# encoding: utf-8
require "mongoid/criterion/complex"
require "mongoid/criterion/exclusion"
require "mongoid/criterion/inclusion"
require "mongoid/criterion/optional"
require "mongoid/criterion/selector"

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
    include Criterion::Exclusion
    include Criterion::Inclusion
    include Criterion::Optional
    include Enumerable

    attr_reader :collection, :ids, :klass, :options, :selector
    attr_accessor :documents

    delegate :aggregate, :avg, :blank?, :count, :distinct, :empty?,
             :execute, :first, :group, :id_criteria, :last, :max,
             :min, :one, :page, :paginate, :per_page, :shift, :sum, :to => :context

    # Concatinate the criteria with another enumerable. If the other is a
    # +Criteria+ then it needs to get the collection from it.
    def +(other)
      entries + comparable(other)
    end

    # Returns the difference between the criteria and another enumerable. If
    # the other is a +Criteria+ then it needs to get the collection from it.
    def -(other)
      entries - comparable(other)
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
        return (execute.entries == other)
      else
        return false
      end
    end

    # Return or create the context in which this criteria should be executed.
    #
    # This will return an Enumerable context if the class is embedded,
    # otherwise it will return a Mongo context for root classes.
    def context
      @context ||= Contexts.context_for(self)
    end

    # Iterate over each +Document+ in the results. This can take an optional
    # block to pass to each argument in the results.
    #
    # Example:
    #
    # <tt>criteria.each { |doc| p doc }</tt>
    def each(&block)
      context.iterate(&block)
      self
    end

    # Return true if the criteria has some Document or not
    #
    # Example:
    #
    # <tt>criteria.exists?</tt>
    def exists?
      context.count > 0
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

    # Create the new +Criteria+ object. This will initialize the selector
    # and options hashes, as well as the type of criteria.
    #
    # Options:
    #
    # type: One of :all, :first:, or :last
    # klass: The class to execute on.
    def initialize(klass)
      @selector = Mongoid::Criterion::Selector.new(klass)
      @options, @klass, @documents = {}, klass, []
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
    # Returns: <tt>Criteria</tt>
    def method_missing(name, *args)
      if @klass.respond_to?(name)
        @klass.send(:with_scope, self) do
          @klass.send(name, *args)
        end
      else
        return entries.send(name, *args)
      end
    end

    alias :to_ary :to_a

    # Returns the selector and options as a +Hash+ that would be passed to a
    # scope for use with named scopes.
    def scoped
      scope_options = @options.dup
      sorting = scope_options.delete(:sort)
      scope_options[:order_by] = sorting if sorting
      { :where => @selector }.merge(scope_options)
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
    # <tt>Criteria.translate(Person, "4ab2bc4b8ad548971900005c")</tt>
    # <tt>Criteria.translate(Person, :conditions => { :field => "value"}, :limit => 20)</tt>
    def self.translate(*args)
      klass = args[0]
      params = args[1] || {}
      unless params.is_a?(Hash)
        return klass.criteria.id_criteria(params)
      end
      conditions = params.delete(:conditions) || {}
      if conditions.include?(:id)
        conditions[:_id] = conditions[:id]
        conditions.delete(:id)
      end
      return klass.criteria.where(conditions).extras(params)
    end

    protected

    # Filters the unused options out of the options +Hash+. Currently this
    # takes into account the "page" and "per_page" options that would be passed
    # in if using will_paginate.
    #
    # Example:
    #
    # Given a criteria with a selector of { :page => 1, :per_page => 40 }
    #
    # <tt>criteria.filter_options</tt> # selector: { :skip => 0, :limit => 40 }
    def filter_options
      page_num = @options.delete(:page)
      per_page_num = @options.delete(:per_page)
      if (page_num || per_page_num)
        @options[:limit] = limits = (per_page_num || 20).to_i
        @options[:skip] = (page_num || 1).to_i * limits - limits
      end
    end

    # Return the entries of the other criteria or the object. Used for
    # comparing criteria or an enumerable.
    def comparable(other)
      other.is_a?(Criteria) ? other.entries : other
    end

    # Update the selector setting the operator on the value for each key in the
    # supplied attributes +Hash+.
    #
    # Example:
    #
    # <tt>criteria.update_selector({ :field => "value" }, "$in")</tt>
    def update_selector(attributes, operator)
      attributes.each do |key, value|
        unless @selector[key]
          @selector[key] = { operator => value }
        else
          if @selector[key].has_key?(operator)
            # add the value to the current operator
            new_value = @selector[key].values.first + value
            @selector[key] = { operator => new_value }
          else
            # create a new operator on this key
            @selector[key][operator] = value
          end        
        end
      end; self
    end
  end
end
