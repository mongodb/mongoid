# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when trying to set a polymorphic "references in" association to a
    # model with multiple "references many/one" associations pointing to that
    # first model.
    #
    # @example Invalid setting of a polymorphic association.
    #   class Face
    #     include Mongoid::Document
    #
    #     has_one :left_eye, class_name: "Eye", as: :eyeable
    #     has_one :right_eye, class_name: "Eye", as: :eyeable
    #   end
    #
    #   class Eye
    #     include Mongoid::Document
    #
    #     belongs_to :eyeable, polymorphic: true
    #   end
    #
    #   eye = Eye.new
    #   face = Face.new
    #   eye.eyeable = face # Raises error

    class InvalidSetPolymorphicRelation < MongoidError

      # Create the new invalid set polymorphic association error.
      #
      # @example Create the error.
      #   InvalidSetPolymorphicRelation.new
      def initialize(name, klass, other_klass)
        super(compose_message("invalid_set_polymorphic_relation", { name: name, klass: klass, other_klass: other_klass }))
      end
    end
  end
end
