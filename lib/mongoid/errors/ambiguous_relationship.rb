# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

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
      def initialize(klass, referenced_klass)
        super(
          compose_message("ambiguous_relationship", { klass: klass, referenced_klass: referenced_klass})
        )
      end
    end
  end
end
