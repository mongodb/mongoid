# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when trying to reference an embedded document from
    # a document in another collection that is not its parent.
    #
    # @example An illegal reference to an embedded document.
    #   class Post
    #     include Mongoid::Document
    #     references_many :addresses
    #   end
    #
    #   class Address
    #     include Mongoid::Document
    #     embedded_in :person
    #     referenced_in :post
    #   end
    #
    # @since 2.0.0
    class MixedRelations < MongoidError
      def initialize(root_klass, embedded_klass)
        super(
          compose_message(
            "mixed_relations",
            { root: root_klass, embedded: embedded_klass }
          )
        )
      end
    end
  end
end
