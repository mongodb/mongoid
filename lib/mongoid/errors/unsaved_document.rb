# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when attempting to call create or create! through a
    # references_many when the parent document has not been saved. This
    # prevents the child from getting persisted and immediately being orphaned.
    class UnsavedDocument < MongoidError
      def initialize(base, document)
        super(
          compose_message(
            "unsaved_document",
            { base: base.class.name, document: document.class.name }
          )
        )
      end
    end
  end
end
