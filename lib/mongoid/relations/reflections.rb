# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Reflections #:nodoc:
      extend ActiveSupport::Concern

      included do

        delegate \
          :reflect_on_association,
          :reflect_on_all_associations, :to => "self.class"
      end

      module ClassMethods #:nodoc

        # Returns the relation metadata for the supplied name.
        #
        # Options:
        #
        # name: The relation name.
        #
        # Example:
        #
        # <tt>Person.reflect_on_association(:addresses)</tt>
        def reflect_on_association(name)
          relations[name.to_s]
        end

        # Returns all relation metadata for the supplied macros.
        #
        # Options:
        #
        # macros: The relation macros
        #
        # Example:
        #
        # <tt>Person.reflect_on_all_associations(:embeds_many)</tt>
        def reflect_on_all_associations(*macros)
          relations.values.select { |meta| macros.include?(meta.macro) }
        end
      end
    end
  end
end
