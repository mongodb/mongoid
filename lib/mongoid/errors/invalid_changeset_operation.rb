# frozen_string_literal: true

module Mongoid
  module Errors
    # Raised when an operation is attempted on a changeset that has already
    # been flushed or discarded.
    class InvalidChangesetOperation < MongoidError
    end
  end
end
