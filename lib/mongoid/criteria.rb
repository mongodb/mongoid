# encoding: utf-8
require "mongoid/criteria/findable"
require "mongoid/criteria/includable"
require "mongoid/criteria/inspectable"
require "mongoid/criteria/marshalable"
require "mongoid/criteria/modifiable"
require "mongoid/criteria/scopable"

module Mongoid

  # The +Criteria+ class is the core object needed in Mongoid to retrieve
  # objects from the database. It is a DSL that essentially sets up the
  # selector and options arguments that get passed on to a Mongo::Collection
  # in the Ruby driver. Each method on the +Criteria+ returns self to they
  # can be chained in order to create a readable criterion to be executed
  # against the database.
  class Criteria
    include Enumerable
    include Contextual
    include Origin::Queryable
    include Findable
    include Inspectable
    include Includable
    include Marshalable
    include Modifiable
    include Scopable
    include Clients::Options

    # Static array used to check with method missing - we only need to ever
    # instantiate once.
    #
    # @since 4.0.0
    CHECK = []

    attr_accessor :embedded, :klass, :parent_document, :metadata

    # Returns true if the supplied +Enumerable+ or +Criteria+ is equal to the results
    # of this +Criteria+ or the criteria itself.
    #
    # @note This will force a database load when called if an enumerable is passed.
    #
    # @param [ Object ] other The other +Enumerable+ or +Criteria+ to compare to.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 1.0.0
    def ==(other)
      return super if other.respond_to?(:selector)
      entries == other
    end

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

    # Tells the criteria that the cursor that gets returned needs to be
    # cached. This is so multiple iterations don't hit the database multiple
    # times, however this is not advisable when working with large data sets
    # as the entire results will get stored in memory.
    #
    # @example Flag the criteria as cached.
    #   criteria.cache
    #
    # @return [ Criteria ] The cloned criteria.
    def cache
      crit = clone
      crit.options.merge!(cache: true)
      crit
    end

    # Will return true if the cache option has been set.
    #
    # @example Is the criteria cached?
    #   criteria.cached?
    #
    # @return [ true, false ] If the criteria is flagged as cached.
    def cached?
      options[:cache] == true
    end

    # Get the documents from the embedded criteria.
    #
    # @example Get the documents.
    #   criteria.documents
    #
    # @return [ Array<Document> ] The documents.
    #
    # @since 3.0.0
    def documents
      @documents ||= []
    end

    # Set the embedded documents on the criteria.
    #
    # @example Set the documents.
    #
    # @param [ Array<Document> ] docs The embedded documents.
    #
    # @return [ Array<Document> ] The embedded documents.
    #
    # @since 3.0.0
    def documents=(docs)
      @documents = docs
    end

    # Is the criteria for embedded documents?
    #
    # @example Is the criteria for embedded documents?
    #   criteria.embedded?
    #
    # @return [ true, false ] If the criteria is embedded.
    #
    # @since 3.0.0
    def embedded?
      !!@embedded
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
      selector.extract_id
    end

    # Adds a criterion to the +Criteria+ that specifies additional options
    # to be passed to the Ruby driver, in the exact format for the driver.
    #
    # @example Add extra params to the criteria.
    # criteria.extras(:limit => 20, :skip => 40)
    #
    # @param [ Hash ] extras The extra driver options.
    #
    # @return [ Criteria ] The cloned criteria.
    #
    # @since 2.0.0
    def extras(extras)
      crit = clone
      crit.options.merge!(extras)
      crit
    end

    # Get the list of included fields.
    #
    # @example Get the field list.
    #   criteria.field_list
    #
    # @return [ Array<String> ] The fields.
    #
    # @since 2.0.0
    def field_list
      if options[:fields]
        options[:fields].keys.reject{ |key| key == "_type" }
      else
        []
      end
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

    # Initialize the new criteria.
    #
    # @example Init the new criteria.
    #   Criteria.new(Band)
    #
    # @param [ Class ] klass The model class.
    #
    # @since 1.0.0
    def initialize(klass)
      @klass = klass
      klass ? super(klass.aliased_fields, klass.fields) : super({}, {})
    end

    # Merges another object with this +Criteria+ and returns a new criteria.
    # The other object may be a +Criteria+ or a +Hash+. This is used to
    # combine multiple scopes together, where a chained scope situation
    # may be desired.
    #
    # @example Merge the criteria with another criteria.
    #   criteri.merge(other_criteria)
    #
    # @example Merge the criteria with a hash. The hash must contain a klass
    #   key and the key/value pairs correspond to method names/args.

    #   criteria.merge({
    #     klass: Band,
    #     where: { name: "Depeche Mode" },
    #     order_by: { name: 1 }
    #   })
    #
    # @param [ Criteria ] other The other criterion to merge with.
    #
    # @return [ Criteria ] A cloned self.
    def merge(other)
      crit = clone
      crit.merge!(other)
      crit
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
      selector.merge!(criteria.selector)
      options.merge!(criteria.options)
      self.documents = criteria.documents.dup unless criteria.documents.empty?
      self.scoping_options = criteria.scoping_options
      self.inclusions = (inclusions + criteria.inclusions).uniq
      self
    end

    # Returns a criteria that will always contain zero results and never hits
    # the database.
    #
    # @example Return a none criteria.
    #   criteria.none
    #
    # @return [ Criteria ] The none criteria.
    #
    # @since 4.0.0
    def none
      @none = true and self
    end

    # Is the criteria an empty but chainable criteria?
    #
    # @example Is the criteria a none criteria?
    #   criteria.empty_and_chainable?
    #
    # @return [ true, false ] If the criteria is a none.
    #
    # @since 4.0.0
    def empty_and_chainable?
      !!@none
    end

    # Overriden to include _type in the fields.
    #
    # @example Limit the fields returned from the database.
    #   Band.only(:name)
    #
    # @param [ Array<Symbol> ] args The names of the fields.
    #
    # @return [ Criteria ] The cloned criteria.
    #
    # @since 1.0.0
    def only(*args)
      return clone if args.flatten.empty?
      args = args.flatten
      if (args & Fields::IDS).empty?
        args.unshift(:_id)
      end
      if klass.hereditary?
        super(*args.push(:_type))
      else
        super(*args)
      end
    end

    # Set the read preference for the criteria.
    #
    # @example Set the read preference.
    #   criteria.read(mode: :primary_preferred)
    #
    # @param [ Hash ] value The mode preference.
    #
    # @return [ Criteria ] The cloned criteria.
    #
    # @since 5.0.0
    def read(value = nil)
      clone.tap do |criteria|
        criteria.options.merge!(read: value)
      end
    end

    # Overriden to exclude _id from the fields.
    #
    # @example Exclude fields returned from the database.
    #   Band.without(:name)
    #
    # @param [ Array<Symbol> ] args The names of the fields.
    #
    # @return [ Criteria ] The cloned criteria.
    #
    # @since 4.0.3
    def without(*args)
      args -= Fields::IDS
      super(*args)
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
      super || klass.respond_to?(name) || CHECK.respond_to?(name, include_private)
    end

    alias :to_ary :to_a

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

    # Adds a criterion to the +Criteria+ that specifies a type or an Array of
    # types that must be matched.
    #
    # @example Match only specific models.
    #   criteria.type('Browser')
    #   criteria.type(['Firefox', 'Browser'])
    #
    # @param [ Array<String> ] types The types to match against.
    #
    # @return [ Criteria ] The cloned criteria.
    def type(types)
      any_in(_type: Array(types))
    end

    # This is the general entry point for most MongoDB queries. This either
    # creates a standard field: value selection, and expanded selection with
    # the use of hash methods, or a $where selection if a string is provided.
    #
    # @example Add a standard selection.
    #   criteria.where(name: "syd")
    #
    # @example Add a javascript selection.
    #   criteria.where("this.name == 'syd'")
    #
    # @param [ String, Hash ] criterion The javascript or standard selection.
    #
    # @raise [ UnsupportedJavascript ] If provided a string and the criteria
    #   is embedded.
    #
    # @return [ Criteria ] The cloned selectable.
    #
    # @since 1.0.0
    def where(expression)
      if expression.is_a?(::String) && embedded?
        raise Errors::UnsupportedJavascript.new(klass, expression)
      end
      super
    end


    # Get a version of this criteria without the options.
    #
    # @example Get the criteria without options.
    #   criteria.without_options
    #
    # @return [ Criteria ] The cloned criteria.
    #
    # @since 3.0.4
    def without_options
      crit = clone
      crit.options.clear
      crit
    end

    # Find documents by the provided javascript and scope. Uses a $where but is
    # different from +Criteria#where+ in that it will pass a code object to the
    # query instead of a pure string. Safe against Javascript injection
    # attacks.
    #
    # @example Find by javascript.
    #   Band.for_js("this.name = param", param: "Tool")
    #
    # @param [ String ] javascript The javascript to execute in the $where.
    # @param [ Hash ] scope The scope for the code.
    #
    # @return [ Criteria ] The criteria.
    #
    # @since 3.1.0
    def for_js(javascript, scope = {})
      js_query(BSON::CodeWithScope.new(javascript, scope))
    end

    private

    # Are documents in the query missing, and are we configured to raise an
    # error?
    #
    # @api private
    #
    # @example Check for missing documents.
    #   criteria.check_for_missing_documents!([], [ 1 ])
    #
    # @param [ Array<Document> ] result The result.
    # @param [ Array<Object> ] ids The ids.
    #
    # @raise [ Errors::DocumentNotFound ] If none are found and raising an
    #   error.
    #
    # @since 3.0.0
    def check_for_missing_documents!(result, ids)
      if (result.size < ids.size) && Mongoid.raise_not_found_error
        raise Errors::DocumentNotFound.new(klass, ids, ids - result.map(&:_id))
      end
    end

    # Clone or dup the current +Criteria+. This will return a new criteria with
    # the selector, options, klass, embedded options, etc intact.
    #
    # @api private
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
    #
    # @since 1.0.0
    def initialize_copy(other)
      @inclusions = other.inclusions.dup
      @scoping_options = other.scoping_options
      @documents = other.documents.dup
      @context = nil
      super
    end

    # Used for chaining +Criteria+ scopes together in the for of class methods
    # on the +Document+ the criteria is for.
    #
    # @example Handle method missing.
    #   criteria.method_missing(:name)
    #
    # @param [ Symbol ] name The method name.
    # @param [ Array ] args The arguments.
    #
    # @return [ Object ] The result of the method call.
    #
    # @since 1.0.0
    def method_missing(name, *args, &block)
      if klass.respond_to?(name)
        klass.send(:with_scope, self) do
          klass.send(name, *args, &block)
        end
      elsif CHECK.respond_to?(name)
        return entries.send(name, *args, &block)
      else
        super
      end
    end

    # For models where inheritance is at play we need to add the type
    # selection.
    #
    # @example Add the type selection.
    #   criteria.merge_type_selection
    #
    # @return [ true, false ] If type selection was added.
    #
    # @since 3.0.3
    def merge_type_selection
      selector.merge!(type_selection) if type_selectable?
    end

    # Is the criteria type selectable?
    #
    # @api private
    #
    # @example If the criteria type selectable?
    #   criteria.type_selectable?
    #
    # @return [ true, false ] If type selection should be added.
    #
    # @since 3.0.3
    def type_selectable?
      klass.hereditary? &&
        !selector.keys.include?("_type") &&
        !selector.keys.include?(:_type)
    end

    # Get the selector for type selection.
    #
    # @api private
    #
    # @example Get a type selection hash.
    #   criteria.type_selection
    #
    # @return [ Hash ] The type selection.
    #
    # @since 3.0.3
    def type_selection
      klasses = klass._types
      if klasses.size > 1
        { _type: { "$in" => klass._types }}
      else
        { _type: klass._types[0] }
      end
    end

    # Get a new selector with type selection in it.
    #
    # @api private
    #
    # @example Get a selector with type selection.
    #   criteria.selector_with_type_selection
    #
    # @return [ Hash ] The selector.
    #
    # @since 3.0.3
    def selector_with_type_selection
      type_selectable? ? selector.merge(type_selection) : selector
    end
  end
end
