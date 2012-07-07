# encoding: utf-8
require "mongoid/criterion/inspection"
require "mongoid/criterion/scoping"

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
    include Criterion::Inspection
    include Criterion::Scoping

    attr_accessor :embedded, :klass

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

    # Build a document given the selector and return it.
    # Complex criteria, such as $in and $or operations will get ignored.
    #
    # @example build the document.
    #   Person.where(:title => "Sir").build
    #
    # @example Build with selectors getting ignored.
    #   Person.where(:age.gt => 5).build
    #
    # @return [ Document ] A non-persisted document.
    #
    # @since 2.0.0
    def build(attrs = {})
      create_document(:new, attrs)
    end
    alias :new :build

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

    # Create a document in the database given the selector and return it.
    # Complex criteria, such as $in and $or operations will get ignored.
    #
    # @example Create the document.
    #   Person.where(:title => "Sir").create
    #
    # @example Create with selectors getting ignored.
    #   Person.where(:age.gt => 5).create
    #
    # @return [ Document ] A newly created document.
    #
    # @since 2.0.0.rc.1
    def create(attrs = {})
      create_document(:create, attrs)
    end

    # Create a document in the database given the selector and return it.
    # Complex criteria, such as $in and $or operations will get ignored.
    # If validation fails, an error will be raised.
    #
    # @example Create the document.
    #   Person.where(:title => "Sir").create
    #
    # @example Create with selectors getting ignored.
    #   Person.where(:age.gt => 5).create
    #
    # @raise [ Errors::Validations ] on a validation error.
    #
    # @return [ Document ] A newly created document.
    #
    # @since 3.0.0
    def create!(attrs = {})
      create_document(:create!, attrs)
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

    # Execute the criteria or raise an error if no documents found.
    #
    # @example Execute or raise
    #   criteria.execute_or_raise(id)
    #
    # @param [ Object ] args The arguments passed.
    #
    # @raise [ Errors::DocumentNotFound ] If nothing returned.
    #
    # @return [ Document, Array<Document> ] The document(s).
    #
    # @since 2.0.0
    def execute_or_raise(ids, multi)
      result = multiple_from_map_or_db(ids)
      check_for_missing_documents!(result, ids)
      multi ? result : result.first
    end

    # Return true if the criteria has some Document or not.
    #
    # @example Are there any documents for the criteria?
    #   criteria.exists?
    #
    # @return [ true, false ] If documents match.
    #
    # @since 1.0.0
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

    # Find the matchind document(s) in the criteria for the provided ids.
    #
    # @example Find by an id.
    #   criteria.find(Moped::BSON::ObjectId.new)
    #
    # @example Find by multiple ids.
    #   criteria.find([ Moped::BSON::ObjectId.new, Moped::BSON::ObjectId.new ])
    #
    # @param [ Array<Moped::BSON::ObjectId> ] args The ids to search for.
    #
    # @return [ Array<Document>, Document ] The matching document(s).
    #
    # @since 1.0.0
    def find(*args)
      ids = args.__find_args__
      raise_invalid if ids.any?(&:nil?)
      for_ids(ids).execute_or_raise(ids, args.multi_arged?)
    end

    # Adds a criterion to the +Criteria+ that specifies an id that must be matched.
    #
    # @example Add a single id criteria.
    #   criteria.for_ids([ 1 ])
    #
    # @example Add multiple id criteria.
    #   criteria.for_ids([ 1, 2 ])
    #
    # @param [ Array ] ids The array of ids.
    #
    # @return [ Criteria ] The cloned criteria.
    def for_ids(ids)
      ids = mongoize_ids(ids)
      method = extract_id ? :all_of : :where
      if ids.size > 1
        send(method, { _id: { "$in" => ids }})
      else
        send(method, { _id: ids.first })
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

    # Get the document from the identity map, and if not found hit the
    # database.
    #
    # @example Get the document from the map or criteria.
    #   criteria.from_map_or_db
    #
    # @return [ Document ] The found document.
    #
    # @since 2.2.1
    def from_map_or_db
      id = extract_id
      id = klass.fields["_id"].mongoize(id) if id
      identifier = id || selector.except("_type")
      doc = IdentityMap.get(klass, identifier)
      identifier_present = IdentityMap.has_identifier?(klass, identifier)
      identifier_present && (doc.nil? || doc && doc.matches?(selector)) ? doc : first
    end

    # Get the documents from the identity map, and if not found hit the
    # database.
    #
    # @example Get the documents from the map or criteria.
    #   criteria.multiple_from_map_or_db(ids)
    #
    # @param [ ids ] The searched ids.
    #
    # @return [ Array<Document> ] The found documents.
    def multiple_from_map_or_db(ids)
      return entries if embedded?
      ids = mongoize_ids(ids)
      result = from_identity_map(ids)
      ids.empty? ? result : result + from_database(ids)
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
      super(klass.aliased_fields, klass.fields)
    end

    # Eager loads all the provided relations. Will load all the documents
    # into the identity map who's ids match based on the extra query for the
    # ids.
    #
    # @note This will only work if Mongoid's identity map is enabled. To do
    #   so set identity_map_enabled: true in your mongoid.yml
    #
    # @note This will work for embedded relations that reference another
    #   collection via belongs_to as well.
    #
    # @note Eager loading brings all the documents into memory, so there is a
    #   sweet spot on the performance gains. Internal benchmarks show that
    #   eager loading becomes slower around 100k documents, but this will
    #   naturally depend on the specific application.
    #
    # @example Eager load the provided relations.
    #   Person.includes(:posts, :game)
    #
    # @param [ Array<Symbol> ] relations The names of the relations to eager
    #   load.
    #
    # @return [ Criteria ] The cloned criteria.
    #
    # @since 2.2.0
    def includes(*relations)
      relations.each do |name|
        metadata = klass.reflect_on_association(name)
        inclusions.push(metadata) unless inclusions.include?(metadata)
      end
      clone
    end

    # Get a list of criteria that are to be executed for eager loading.
    #
    # @example Get the eager loading inclusions.
    #   Person.includes(:game).inclusions
    #
    # @return [ Array<Metadata> ] The inclusions.
    #
    # @since 2.2.0
    def inclusions
      @inclusions ||= []
    end

    # Set the inclusions for the criteria.
    #
    # @example Set the inclusions.
    #   criteria.inclusions = [ meta ]
    #
    # @param [ Array<Metadata> ] The inclusions.
    #
    # @return [ Array<Metadata> ] The new inclusions.
    #
    # @since 3.0.0
    def inclusions=(value)
      @inclusions = value
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
      self.inclusions = (inclusions + criteria.inclusions.dup).uniq
      self
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
      return clone if args.empty?
      args = args.flatten
      if klass.hereditary?
        super(*args.push(:_type))
      else
        super(*args)
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
      super || klass.respond_to?(name) || entries.respond_to?(name, include_private)
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

    # Create a document given the provided method and attributes from the
    # existing selector.
    #
    # @api private
    #
    # @example Create a new document.
    #   criteria.create_document(:new, {})
    #
    # @param [ Symbol ] method Either :new or :create.
    # @param [ Hash ] attrs Additional attributes to use.
    #
    # @return [ Document ] The new or saved document.
    #
    # @since 3.0.0
    def create_document(method, attrs = {})
      klass.__send__(method,
        selector.reduce(attrs) do |hash, (key, value)|
          unless key.to_s =~ /\$/ || value.is_a?(Hash)
            hash[key] = value
          end
          hash
        end
      )
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
      @selector = other.selector.dup
      @options = other.options.dup
      @inclusions = other.inclusions.dup
      @scoping_options = other.scoping_options
      @documents = other.documents.dup
      @context = nil
    end

    # Get documents from the database only.
    #
    # @api private
    #
    # @example Get documents from the database.
    #   criteria.from_database(ids)
    #
    # @param [ Array<Object> ] ids The ids to fetch with.
    #
    # @return [ Array<Document> ] The matching documents.
    #
    # @since 3.0.0
    def from_database(ids)
      (ids.size > 1 ? any_in(id: ids) : where(id: ids.first)).entries
    end

    # Get documents from the identity map only.
    #
    # @api private
    #
    # @example Get documents from the identity map.
    #   criteria.from_identity_map(ids)
    #
    # @param [ Array<Object> ] ids The ids to fetch with.
    #
    # @return [ Array<Document> ] The matching documents.
    #
    # @since 3.0.0
    def from_identity_map(ids)
      result = []
      ids.reject! do |id|
        doc = IdentityMap.get(klass, id)
        doc && doc.matches?(selector) ? result.push(doc) : false
      end
      result
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
      else
        return entries.send(name, *args)
      end
    end

    # Convert all the ids to their proper types.
    #
    # @api private
    #
    # @example Convert the ids.
    #   criteria.mongoize_ids(ids)
    #
    # @param [ Array<Object> ] ids The ids to convert.
    #
    # @return [ Array<Object> ] The converted ids.
    #
    # @since 3.0.0
    def mongoize_ids(ids)
      ids.map{ |id| klass.fields["_id"].mongoize(id) }
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
  end
end
