# encoding: utf-8
module Mongoid #:nodoc:

  # Include this module to get automatic versioning of root level documents.
  # This will add a version field to the +Document+ and a has_many association
  # with all the versions contained in it.
  module Versioning
    extend ActiveSupport::Concern

    included do
      field :version, :type => Integer, :default => 1

      embeds_many :versions, :class_name => self.name, :validate => false
      set_callback :save, :before, :revise, :if => :revisable?

      class_attribute :version_max
      delegate :version_max, :to => "self.class"
    end

    # Create a new version of the +Document+. This will load the previous
    # document from the database and set it as the next version before saving
    # the current document. It then increments the version number. If a #max_versions
    # limit is set in the model and it's exceeded, the oldest version gets discarded.
    #
    # @example Revise the document.
    #   person.revise
    #
    # @since 1.0.0
    def revise
      previous = find_last_version
      if previous
        versions.target << previous.clone
        versions.shift if version_max.present? && versions.length > version_max
        self.version = (version || 1 ) + 1
        @modifications["versions"] = [ nil, versions.as_document ] if @modifications
      end
    end

    # Executes a block that temporarily disables versioning. This is for cases
    # where you do not want to version on every save.
    #
    # @example Execute a save without versioning.
    #   person.versionless(&:save)
    #
    # @return [ Object ] The document or result of the block execution.
    #
    # @since 2.0.0
    def versionless
      @versionless = true
      result = yield(self) if block_given?
      @versionless = false
      result || self
    end

    private

    # Find the previous version of this document in the database, or if the
    # document had been saved without versioning return the persisted one.
    #
    # @example Find the last version.
    #   document.find_last_version
    #
    # @return [ Document, nil ] The previously saved document.
    #
    # @since 2.0.0
    def find_last_version
      self.class.
        where(:_id => id).
        any_of({ :version => version }, { :version => nil }).first
    end

    # Is the document able to be revised? This is true if the document has
    # changed and we have not explicitly told it not to version.
    #
    # @example Is the document revisable?
    #   document.revisable?
    #
    # @return [ true, false ] If the document is revisable.
    #
    # @since 2.0.0
    def revisable?
      changed? && !versionless?
    end

    # Are we in versionless mode? This is true if in a versionless block on the
    # document.
    #
    # @example Is the document in versionless mode?
    #   document.versionless?
    #
    # @return [ true, false ] Is the document not currently versioning.
    #
    # @since 2.0.0
    def versionless?
      !!@versionless
    end

    module ClassMethods #:nodoc:

      # Sets the maximum number of versions to store.
      #
      # @example Set the maximum.
      #   Person.max_versions(5)
      #
      # @param [ Integer ] number The maximum number to store.
      #
      # @return [ Integer ] The max number of versions.
      def max_versions(number)
        self.version_max = number.to_i
      end
    end
  end
end
