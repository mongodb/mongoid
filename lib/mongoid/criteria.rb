# encoding: utf-8
require "mongoid/criterion/builder"
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
    include Criterion::Builder
    include Criterion::Creational
    include Criterion::Exclusion
    include Criterion::Inclusion
    include Criterion::Inspection
    include Criterion::Optional

    attr_accessor \
      :collection,
      :documents,
      :embedded,
      :ids,
      :klass,
      :options,
      :selector,
      :field_list

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

    # When freezing a criteria we need to initialize the context first
    # otherwise the setting of the context on attempted iteration will raise a
    # runtime error.
    #
    # @example Freeze the criteria.
    #   criteria.freeze
    #
    # @return [ Criteria ] The frozen criteria.
    #
    # @since 2.0.0
    def freeze
      context and super
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
        if other.is_a?(Criteria)
          crit.selector.update(other.selector)
          crit.options.update(other.options)
          crit.documents = other.documents
        else
          duped = other.dup
          crit.selector.update(duped.delete(:conditions) || {})
          crit.options.update(duped)
        end
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

    # Returns true if criteria responds to the given method.
    #
    # Options:
    #
    # name: The name of the class method on the +Document+.
    # include_private: The arguments passed to the method.
    #
    # Example:
    #
    # <tt>criteria.respond_to?(:batch_update)</tt>
    def respond_to?(name, include_private = false)
      # don't include klass private methods because method_missing won't call them
      super || @klass.respond_to?(name) || entries.respond_to?(name, include_private)
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

    # Search for documents based on a variety of args.
    #
    # @example Find by an id.
    #   criteria.search(BSON::ObjectId.new)
    #
    # @example Find by multiple ids.
    #   criteria.search([ BSON::ObjectId.new, BSON::ObjectId.new ])
    #
    # @example Conditionally find all matching documents.
    #   criteria.search(:all, :conditions => { :title => "Sir" })
    #
    # @example Conditionally find the first document.
    #   criteria.search(:first, :conditions => { :title => "Sir" })
    #
    # @example Conditionally find the last document.
    #   criteria.search(:last, :conditions => { :title => "Sir" })
    #
    # @param [ Symbol, BSON::ObjectId, Array<BSON::ObjectId> ] arg The
    #   argument to search with.
    # @param [ Hash ] options The options to search with.
    #
    # @return [ Array<Symbol, Criteria> ] The type and criteria.
    #
    # @since 2.0.0
    def search(*args)
      raise_invalid if args[0].nil?
      type = args[0]
      params = args[1] || {}
      return [ :ids, for_ids(type) ] unless type.is_a?(Symbol)
      conditions = params.delete(:conditions) || {}
      if conditions.include?(:id)
        conditions[:_id] = conditions[:id]
        conditions.delete(:id)
      end
      return [ type, where(conditions).extras(params) ]
    end

    # Convenience method of raising an invalid options error.
    #
    # @example Raise the error.
    #   criteria.raise_invalid
    #
    # @raise [ Errors::InvalidOptions ] The error.
    #
    # @since 2.0.0
    def raise_invalid
      raise Errors::InvalidOptions.new(:calling_document_find_with_nil_is_invalid, {})
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
    #
    # @param [ Symbol ] combine The operator to use when combining sets.
    def update_selector(attributes, operator, combine = :+)
      clone.tap do |crit|
        converted = BSON::ObjectId.convert(klass, attributes || {})
        converted.each do |key, value|
          unless crit.selector[key]
            crit.selector[key] = { operator => value }
          else
            if crit.selector[key].has_key?(operator)
              new_value = crit.selector[key].values.first.send(combine, value)
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
