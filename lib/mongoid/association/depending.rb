# frozen_string_literal: true

module Mongoid
  module Association

    # This module defines the behavior for setting up cascading deletes and
    # nullifies for associations, and how to delegate to the appropriate strategy.
    module Depending
      extend ActiveSupport::Concern

      included do
        class_attribute :dependents

        # @api private
        class_attribute :dependents_owner

        self.dependents = []
        self.dependents_owner = self
      end

      class_methods do
        # @api private
        def _all_dependents
          superclass_dependents = superclass.respond_to?(:_all_dependents) ? superclass._all_dependents : []
          dependents + superclass_dependents.reject do |new_dep|
            dependents.any? do |old_dep| old_dep.name == new_dep.name
            end
          end
        end
      end

      # The valid dependent strategies.
      STRATEGIES = [
          :delete_all,
          :destroy,
          :nullify,
          :restrict_with_exception,
          :restrict_with_error
      ]

      # Attempt to add the cascading information for the document to know how
      # to handle associated documents on a removal.
      #
      # @example Set up cascading information
      #   Mongoid::Association::Depending.define_dependency!(association)
      #
      # @param [ Association ] association The association metadata.
      #
      # @return [ Class ] The class of the document.
      def self.define_dependency!(association)
        validate!(association)
        association.inverse_class.tap do |klass|
          if klass.dependents_owner != klass
            klass.dependents = []
            klass.dependents_owner = klass
          end

          if association.dependent && !klass.dependents.include?(association)
            klass.dependents.push(association)
          end
        end
      end

      def self.validate!(association)
        unless STRATEGIES.include?(association.dependent)
          raise Errors::InvalidDependentStrategy.new(association,
                                                     association.dependent,
                                                     STRATEGIES)
        end
      end

      # Perform all cascading deletes, destroys, or nullifies. Will delegate to
      # the appropriate strategy to perform the operation.
      #
      # @example Execute cascades.
      #   document.apply_destroy_dependencies!
      def apply_destroy_dependencies!
        self.class._all_dependents.each do |association|
          if dependent = association.try(:dependent)
            send("_dependent_#{dependent}!", association)
          end
        end
      end

      private

      def _dependent_delete_all!(association)
        if relation = send(association.name)
          if relation.respond_to?(:dependents) && relation.dependents.blank?
            relation.clear
          else
            ::Array.wrap(send(association.name)).each { |rel| rel.delete }
          end
        end
      end

      def _dependent_destroy!(association)
        if relation = send(association.name)
          if relation.is_a?(Enumerable)
            relation.entries
            relation.each { |doc| doc.destroy }
          else
            relation.destroy
          end
        end
      end

      def _dependent_nullify!(association)
        if relation = send(association.name)
          relation.nullify
        end
      end

      def _dependent_restrict_with_exception!(association)
        if (relation = send(association.name)) && !relation.blank?
          raise Errors::DeleteRestriction.new(relation, association.name)
        end
      end

      def _dependent_restrict_with_error!(association)
        if (relation = send(association.name)) && !relation.blank?
          errors.add(association.name, :destroy_restrict_with_error_dependencies_exist)
          throw(:abort, false)
        end
      end
    end
  end
end
