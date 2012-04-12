# encoding: utf-8
module Mongoid #:nodoc:

  # This is the base module for all domain objects that need to be persisted to
  # the database as documents.
  module Document
    extend ActiveSupport::Concern
    include Mongoid::Components
  end
end

ActiveSupport.run_load_hooks(:mongoid, Mongoid::Document)
