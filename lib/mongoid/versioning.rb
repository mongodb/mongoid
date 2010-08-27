# encoding: utf-8
module Mongoid #:nodoc:
  # Include this module to get automatic versioning of root level documents.
  # This will add a version field to the +Document+ and a has_many association
  # with all the versions contained in it.
  module Versioning
    extend ActiveSupport::Concern

    included do
      field :version, :type => Integer, :default => 1
      embeds_many :versions, :class_name => self.name
      set_callback :save, :before, :revise
    end

    module ClassMethods #:nodoc:
      attr_accessor :version_max
      def max_versions(number)
        self.version_max = number.to_i
      end
    end

    # Create a new version of the +Document+. This will load the previous
    # document from the database and set it as the next version before saving
    # the current document. It then increments the version number. If a #max_versions
    # limit is set in the model and it's exceeded, the oldest version gets discarded.
    def revise
      last_version = self.class.first(:conditions => { :_id => id, :version => version })
      if last_version
        self.versions << last_version.clone
        self.versions.shift if self.class.version_max.present? && self.versions.length > self.class.version_max
        self.version = version + 1
        @modifications["versions"] = [ nil, @attributes["versions"] ] if @modifications
      end
    end
  end
end
