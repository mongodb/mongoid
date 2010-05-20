# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    module ForeignKey #:nodoc:
      extend ActiveSupport::Concern

      module ClassMethods #:nodoc:
        # Determine the value for the foreign key constriant field in the
        # database, based on the type of association or if the actual value was
        # supplied as an option.
        #
        # Example:
        #
        # <tt>contraint(:posts, {}, :references_one)</tt>
        #
        # Returns
        #
        # A +String+ for the foreign key field.
        def constraint(name, options, association)
          key = options[:foreign_key]

          # Always return the supplied foreign_key option if it was supplied -
          # the user should always be ble to override.
          return key.to_s if key

          case association
          when :one, :many then self.name.foreign_key
          when :many_as_array then "#{name.to_s.singularize}_ids"
          else name.to_s.foreign_key
          end
        end
      end
    end
  end
end
