# encoding: utf-8
require "mongoid/persistence/atomic"

module Mongoid

  # The persistence module is a mixin to provide database accessor methods for
  # the document. These correspond to the appropriate accessors on a
  # mongo collection and retain the same DSL.
  #
  # @example Sample persistence operations.
  #   document.insert
  #   document.update
  #   document.upsert
  module Persistence
    extend ActiveSupport::Concern
    include Atomic
    include Mongoid::Atomic::Positionable
  end
end
