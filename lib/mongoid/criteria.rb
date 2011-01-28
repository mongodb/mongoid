# encoding: utf-8
require "mongoid/criterion/creational"
require "mongoid/criterion/complex"
require "mongoid/criterion/exclusion"
require "mongoid/criterion/inclusion"
require "mongoid/criterion/inspection"
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
    include Enumerable
    include Criterion::Creational
    include Criterion::Exclusion
    include Criterion::Inclusion
    include Criterion::Inspection
    include Criterion::Optional

    attr_accessor :collection, :documents, :embedded, :ids, :klass, :options, :selector

    delegate \
      :aggregate,
      :avg,
      :blank?,
      :count,
      :delete,
      :delete_all,
      :destroy,
      :destroy_all,
      :distinct,
      :empty?,
      :execute,
      :first,
      :group,
      :id_criteria,
      :last,
      :max,
      :min,
      :one,
      :page,
      :paginate,
      :per_page,
      :shift,
      :sum,
      :update,
      :update_all, :to => :context

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
      @context ||= Contexts.context_for(self, embedded)
    end

    # Iterate over each +Document+ in the results. This can take an optional
    # block to pass to each argument in the results.
    #
    # Example:
    #
    # <tt>criteria.each { |doc| p doc }</tt>
    def each(&block)
      tap { context.iterate(&block) }
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
    def initialize(klass, embedded = false)
      @selector = Criterion::Selector.new(klass)
      @options, @klass, @documents, @embedded = {}, klass, [], embedded
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
      clone.tap do |crit|
        crit.selector.update(other.selector)
        crit.options.update(other.options)
        crit.documents = other.documents
      end
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

    # Returns the selector and options as a +Hash+ that would be passed to a
    # scope for use with named scopes.
    def scoped
      scope_options = @options.dup
      sorting = scope_options.delete(:sort)
      scope_options[:order_by] = sorting if sorting
      { :where => @selector }.merge(scope_options)
    end
    alias :to_ary :to_a

    # Needed to properly get a criteria back as json
    #
    # @example Get the criteria as json.
    #   Person.where(:title => "Sir").as_json
    #
    # @param [ Hash ] options Options to pass through to the serializer.
    #
    # @return [ String ] The JSON string.
    def as_json(options = nil)
      entries.as_json(options)
    end

    class << self

      # Encaspulates the behavior of taking arguments and parsing them into a
      # finder type and a corresponding criteria object.
      #
      # Example:
      #
      # <tt>Criteria.parse!(Person, :all, :conditions => {})</tt>
      #
      # Options:
      #
      # klass: The klass to create the criteria for.
      # args: An assortment of finder options.
      #
      # Returns:
      #
      # An Array with the type and criteria.
      def parse!(klass, embedded, *args)
        if args[0].nil?
          Errors::InvalidOptions.new("Calling Document#find with nil is invalid")
        end
        type = args.delete_at(0) if args[0].is_a?(Symbol)
        criteria = translate(klass, embedded, *args)
        return [ type, criteria ]
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
      def translate(*args)
        klass = args[0]
        embedded = args[1]
        params = args[2] || {}
        unless params.is_a?(Hash)
          return klass.criteria(embedded).id_criteria(params)
        end
        conditions = params.delete(:conditions) || {}
        if conditions.include?(:id)
          conditions[:_id] = conditions[:id]
          conditions.delete(:id)
        end
        return klass.criteria(embedded).where(conditions).extras(params)
      end
    end

    protected

    # Return the entries of the other criteria or the object. Used for
    # comparing criteria or an enumerable.
    def comparable(other)
      other.is_a?(Criteria) ? other.entries : other
    end

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

    # Clone or dup the current +Criteria+. This will return a new criteria with
    # the selector, options, klass, embedded options, etc intact.
    #
    # Example:
    #
    # <tt>criteria.clone</tt>
    # <tt>criteria.dup</tt>
    #
    # Options:
    #
    # other: The criteria getting cloned.
    #
    # Returns:
    #
    # A new identical criteria
    def initialize_copy(other)
      @selector = other.selector.dup
      @options = other.options.dup
      @context = nil
    end

    # Update the selector setting the operator on the value for each key in the
    # supplied attributes +Hash+.
    #
    # Example:
    #
    # <tt>criteria.update_selector({ :field => "value" }, "$in")</tt>
    def update_selector(attributes, operator)
      clone.tap do |crit|
        converted = BSON::ObjectId.convert(klass, attributes || {})
        converted.each do |key, value|
          unless crit.selector[key]
            crit.selector[key] = { operator => value }
          else
            if crit.selector[key].has_key?(operator)
              new_value = crit.selector[key].values.first + value
              crit.selector[key] = { operator => new_value }
            else
              crit.selector[key][operator] = value
            end
          end
        end
      end
    end
  end
end
