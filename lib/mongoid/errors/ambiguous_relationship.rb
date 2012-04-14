# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised in case of an ambigous relationship.
    #
    # @example An ambigous relationship.
    #   class Person
    #     include Mongoid::Document
    #
    #     has_many :invitations, inverse_of: :person
    #     has_many :referred_invitations, class_name: "Invitation", inverse_of: :referred_by
    #   end
    #
    #   class Invitation
    #     include Mongoid::Document
    #
    #     belongs_to :person
    #     belongs_to :referred_by, class_name: "Person"
    #   end
    class AmbiguousRelationship < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   AmbiguousRelationship.new(
      #     Person, Drug, :person, [ :drugs, #   :evil_drugs ]
      #   )
      #
      # @param [ Class ] klass The base class.
      # @param [ Class ] inverse The inverse class.
      # @param [ Symbol ] name The relation name.
      # @param [ Array<Symbol> ] candidates The potential inverses.
      #
      # @since 3.0.0
      def initialize(klass, inverse, name, candidates)
        super(
          compose_message(
            "ambiguous_relationship",
            {
              klass: klass,
              inverse: inverse,
              name: name.inspect,
              candidates: candidates.map(&:inspect).join(", ")
            }
          )
        )
      end
    end
  end
end
