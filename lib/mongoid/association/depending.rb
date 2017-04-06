module Mongoid
  module Association

    # This module defines the behaviour for setting up cascading deletes and
    # nullifies for relations, and how to delegate to the appropriate strategy.
    module Depending
      extend ActiveSupport::Concern

      included do
        class_attribute :dependents
        self.dependents = []
      end

      STRATEGIES = [
          :delete_all,
          :destroy,
          :nullify,
          :restrict_with_exception,
          :restrict_with_error
      ]

      RESTRICT_ERROR_MSG = 'Cannot delete record because dependent members exist.'.freeze

      # Perform all cascading deletes, destroys, or nullifies. Will delegate to
      # the appropriate strategy to perform the operation.
      #
      # @example Execute cascades.
      #   document.cascade!
      #
      # @since 2.0.0.rc.1
      def apply_delete_dependencies!
        dependents.each do |association|
          if association.try(:dependent)
            send("_dependent_#{association.dependent}!", association)
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
          errors.add(association.name, RESTRICT_ERROR_MSG)
          throw(:abort, false)
        end
      end

      # Attempt to add the cascading information for the document to know how
      # to handle associated documents on a removal.
      #
      # @example Set up cascading information
      #   Mongoid::Association::Depending.define_dependency!(association)
      #
      # @param [ Association ] association The association metadata.
      #
      # @return [ Class ] The class of the document.
      #
      # @since 2.0.0.rc.1
      def self.define_dependency!(association)
        validate!(association)
        association.inverse_class.tap do |klass|
          if association.dependent && !klass.dependents.include?(association)
            klass.dependents.push(association)
          end
        end
      end

      private

      def self.validate!(association)
        unless STRATEGIES.include?(association.dependent)
          raise Errors::InvalidDependentStrategy.new(association,
                                                     association.dependent,
                                                     STRATEGIES)
        end
      end
    end
  end
end
