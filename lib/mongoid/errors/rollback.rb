# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Errors

    # This error should be raised to deliberately rollback a transaction without
    # passing on an exception.
    # Normally, raising an exception inside a Mongoid transaction causes rolling
    # the MongoDB transaction back, and the exception is passed on.
    # If Mongoid::Error::Rollback exception is raised, then the MongoDB
    # transaction will be rolled back, without passing on the exception.
    class Rollback < MongoidError; end
  end
end
