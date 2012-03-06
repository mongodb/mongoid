# encoding: utf-8
require "mongoid/criterion/builder"
require "mongoid/criterion/creational"
require "mongoid/criterion/complex"
require "mongoid/criterion/exclusion"
require "mongoid/criterion/inclusion"
require "mongoid/criterion/inspection"
require "mongoid/criterion/optional"
require "mongoid/criterion/scoping"
require "mongoid/criterion/selector"

module Mongoid #:nodoc:

  # The +Criteria+ class is the core object needed in Mongoid to retrieve
  # objects from the database. It is a DSL that essentially sets up the
  # selector and options arguments that get passed on to a Mongo::Collection
  # in the Ruby driver. Each method on the +Criteria+ returns self to they
  # can be chained in order to create a readable criterion to be executed
  # against the database.
  #
  # @example Create and execute a criteria.
  #   criteria = Criteria.new
  #   criteria.only(:field).where(:field => "value").skip(20).limit(20)
  #   criteria.execute
  class Criteria
    include Enumerable
    include Criterion::Builder
    include Criterion::Creational
    include Criterion::Exclusion
    include Criterion::Inclusion
    include Criterion::Inspection
    include Criterion::Optional
    include Criterion::Scoping

    attr_accessor \
      :documents,
      :embedded,
      :ids,
      :klass,
      :options,
      :selector,
      :field_list

    delegate \
      :add_to_set,
      :aggregate,
      :avg,
      :blank?,
      :count,
      :size,
      :length,
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
      :pull,
      :shift,
      :sum,
      :update,
      :update_all, to: :context

    # Concatinate the criteria with another enumerable. If the other is a
    # +Criteria+ then it needs to get the collection from it.
    #
    # @example Concat 2 criteria.
    #   criteria + criteria
    #
    # @param [ Criteria ] other The other criteria.
    def +(other)
      entries + comparable(other)
    end

    # Returns the difference between the criteria and another enumerable. If
    # the other is a +Criteria+ then it needs to get the collection from it.
    #
    # @example Get the difference of 2 criteria.
    #   criteria - criteria
    #
    # @param [ Criteria ] other The other criteria.
    def -(other)
      entries - comparable(other)
    end

    # Returns true if the supplied +Enumerable+ or +Criteria+ is equal to the results
    # of this +Criteria+ or the criteria itself.
    #
    # @note This will force a database load when called if an enumerable is passed.
    #
    # @param [ Object ] other The other +Enumerable+ or +Criteria+ to compare to.
    #
    # @return [ true, false ] If the objects are equal.
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

    # Get the collection associated with the criteria.
    #
    # @example Get the collection.
    #   criteria.collection
    #
    # @return [ Collection ] The collection.
    #
    # @since 2.2.0
    def collection
      klass.collection
    end

    # Return or create the context in which this criteria should be executed.
    #
    # This will return an Enumerable context if the class is embedded,
    # otherwise it will return a Mongo context for root classes.
    #
    # @example Get the appropriate context.
    #   criteria.context
    #
    # @return [ Mongo, Enumerable ] The appropriate context.
    def context
      @context ||= Contexts.context_for(self, embedded)
    end

    # Iterate over each +Document+ in the results. This can take an optional
    # block to pass to each argument in the results.
    #
    # @example Iterate over the criteria results.
    #   criteria.each { |doc| p doc }
    #
    # @return [ Criteria ] The criteria itself.
    def each(&block)
      tap { context.iterate(&block) }
    end

    # Return the cursor for the given collection.
    #
    # @example call :next on the collection cursor
    #   cur = criteria.cursor
    #   cur.next
    #
    # @return [ Cursor ] The appropriate cursor.
    def cursor
      collection.cursor
    end

    # Return true if the criteria has some Document or not.
    #
    # @example Are there any documents for the criteria?
    #   criteria.exists?
    #
    # @return [ true, false ] If documents match.
    def exists?
      context.count > 0
    end

    # Extract a single id from the provided criteria. Could be in an $and
    # query or a straight _id query.
    #
    # @example Extract the id.
    #   criteria.extract_id
    #
    # @return [ Object ] The id.
    #
    # @since 2.3.0
    def extract_id
      selector[:_id]
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
      context and inclusions and super
    end

    # Merges the supplied argument hash into a single criteria
    #
    # @example Fuse the criteria and the object.
    #   criteria.fuse(:where => { :field => "value"}, :limit => 20)
    #
    # @param [ Hash ] criteria_conditions Criteria keys and values.
    #
    # @return [ Criteria ] self.
    def fuse(criteria_conditions = {})
      criteria_conditions.inject(self) do |criteria, (key, value)|
        criteria.send(key, value)
      end
    end

    # Create the new +Criteria+ object. This will initialize the selector
    # and options hashes, as well as the type of criteria.
    #
    # @example Instantiate a new criteria.
    #   Criteria.new(Model, true)
    #
    # @param [ Class ] klass The model the criteria is for.
    # @param [ true, false ] embedded Is the criteria for embedded docs.
    def initialize(klass)
      @selector = Criterion::Selector.new(klass)
      @options, @klass, @documents, @embedded = {}, klass, [], false
    end

    # Merges another object with this +Criteria+ and returns a new criteria.
    # The other object may be a +Criteria+ or a +Hash+. This is used to
    # combine multiple scopes together, where a chained scope situation
    # may be desired.
    #
    # @example Merge the criteria with another criteria.
    #   criteri.merge(other_criteria)
    #
    # @param [ Criteria ] other The other criterion to merge with.
    #
    # @return [ Criteria ] A cloned self.
    def merge(other)
      clone.tap do |criteria|
        criteria.merge!(other)
      end
    end

    # Merge the other criteria into this one.
    #
    # @example Merge another criteria into this criteria.
    #   criteria.merge(Person.where(name: "bob"))
    #
    # @param [ Criteria ] other The criteria to merge in.
    #
    # @return [ Criteria ] The merged criteria.
    #
    # @since 3.0.0
    def merge!(other)
      criteria = other.to_criteria
      tap do |crit|
        crit.selector.update(criteria.selector)
        crit.options.update(criteria.options)
        crit.documents = criteria.documents
        crit.scoping_options = criteria.scoping_options
        crit.inclusions = (crit.inclusions + criteria.inclusions.dup).uniq
      end
    end

    # Returns true if criteria responds to the given method.
    #
    # @example Does the criteria respond to the method?
    #   crtiteria.respond_to?(:each)
    #
    # @param [ Symbol ] name The name of the class method on the +Document+.
    # @param [ true, false ] include_private Whether to include privates.
    #
    # @return [ true, false ] If the criteria responds to the method.
    def respond_to?(name, include_private = false)
      # don't include klass private methods because method_missing won't call them
      super || @klass.respond_to?(name) || entries.respond_to?(name, include_private)
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

    # Convenience method of raising an invalid options error.
    #
    # @example Raise the error.
    #   criteria.raise_invalid
    #
    # @raise [ Errors::InvalidOptions ] The error.
    #
    # @since 2.0.0
    def raise_invalid
      raise Errors::InvalidFind.new
    end

    # Convenience for objects that want to be merged into a criteria.
    #
    # @example Convert to a criteria.
    #   criteria.to_criteria
    #
    # @return [ Criteria ] self.
    #
    # @since 3.0.0
    def to_criteria
      self
    end

    # Convert the criteria to a proc.
    #
    # @example Convert the criteria to a proc.
    #   criteria.to_proc
    #
    # @return [ Proc ] The wrapped criteria.
    #
    # @since 3.0.0
    def to_proc
      ->{ self }
    end

    protected

    # Return the entries of the other criteria or the object. Used for
    # comparing criteria or an enumerable.
    #
    # @example Get the comparable version.
    #   criteria.comparable(other)
    #
    # @param [ Criteria ] other Another criteria.
    #
    # @return [ Array ] The array to compare with.
    def comparable(other)
      other.is_a?(Criteria) ? other.entries : other
    end

    # Get the raw driver collection from the criteria.
    #
    # @example Get the raw driver collection.
    #   criteria.driver
    #
    # @return [ Mongo::Collection ] The driver collection.
    #
    # @since 2.2.0
    def driver
      collection.driver
    end

    # Clone or dup the current +Criteria+. This will return a new criteria with
    # the selector, options, klass, embedded options, etc intact.
    #
    # @example Clone a criteria.
    #   criteria.clone
    #
    # @example Dup a criteria.
    #   criteria.dup
    #
    # @param [ Criteria ] other The criteria getting cloned.
    #
    # @return [ nil ] nil.
    def initialize_copy(other)
      @selector = other.selector.dup
      @options = other.options.dup
      @includes = other.inclusions.dup
      @scoping_options = other.scoping_options
      @context = nil
    end

    # Used for chaining +Criteria+ scopes together in the for of class methods
    # on the +Document+ the criteria is for.
    def method_missing(name, *args, &block)
      if klass.respond_to?(name)
        klass.send(:with_scope, self) do
          klass.send(name, *args, &block)
        end
      else
        return entries.send(name, *args)
      end
    end

    # Update the selector setting the operator on the value for each key in the
    # supplied attributes +Hash+.
    #
    # @example Update the selector.
    #   criteria.update_selector({ :field => "value" }, "$in")
    #
    # @param [ Hash, Array ] attributes The values to convert and apply.
    # @param [ String ] operator The MongoDB operator.
    # @param [ Symbol ] combine The operator to use when combining sets.
    def update_selector(attributes, operator, combine = :+)
      clone.tap do |crit|
        converted = BSON::ObjectId.convert(klass, attributes || {})
        converted.each_pair do |key, value|
          existing = crit.selector[key]
          unless existing
            crit.selector[key] = { operator => value }
          else
            if existing.respond_to?(:merge)
              if existing.has_key?(operator)
                new_value = existing.values.first.send(combine, value)
                crit.selector[key] = { operator => new_value }
              else
                crit.selector[key][operator] = value
              end
            else
              crit.selector[key] = { operator => value }
            end
          end
        end
      end
    end
  end
end
