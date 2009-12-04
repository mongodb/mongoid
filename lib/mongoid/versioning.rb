# encoding: utf-8
module Mongoid #:nodoc:
  # Include this module to get automatic versioning of root level documents.
  # This will add a version field to the +Document+ and a has_many association
  # with all the versions contained in it.
  module Versioning
    def self.included(base)
      base.class_eval do
        field :version, :type => Integer, :default => 1
        has_many :versions, :class_name => self.name
        before_save :revise
        include InstanceMethods
      end
    end
    module InstanceMethods
      # Create a new version of the +Document+. This will load the previous
      # document from the database and set it as the next version before saving
      # the current document. It then increments the version number.
      def revise
        last_version = self.class.first(:conditions => { :_id => id, :version => version })
        if last_version
          self.versions << last_version.clone
          self.version = version + 1
        end
      end
    end
  end
end
