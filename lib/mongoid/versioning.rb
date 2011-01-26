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
      set_callback :save, :before, :revise, :if => :changed?

      delegate :version_max, :to => "self.class"
    end

    # Create a new version of the +Document+. This will load the previous
    # document from the database and set it as the next version before saving
    # the current document. It then increments the version number. If a #max_versions
    # limit is set in the model and it's exceeded, the oldest version gets discarded.
    #
    # @example Revise the document.
    #   person.revise
    def revise
      last_version = self.class.first(:conditions => { :_id => id, :version => version })
      if last_version
        versions.target << last_version.clone
        versions.shift if version_max.present? && versions.length > version_max
        self.version = (version || 1 ) + 1
        @modifications["versions"] = [ nil, versions.as_document ] if @modifications
      end
    end

    module ClassMethods #:nodoc:
      attr_accessor :version_max

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
