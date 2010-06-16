# encoding: utf-8
module Mongoid #:nodoc:
  module Atomicity #:nodoc:
    extend ActiveSupport::Concern

    # Get all the atomic updates that need to happen for the current
    # +Document+. This will include all changes that need to happen in the
    # entire hierarchy that exists below where the save call was made.
    #
    # Example:
    #
    # <tt>person.save</tt> # Saves entire tree
    #
    # Returns:
    #
    # A +Hash+ of all atomic updates that need to occur.
    def _updates
      _children.inject({ "$set" => _sets, "$push" => {}}) do |updates, child|
        updates["$set"].update(child._sets)
        updates["$push"].update(child._pushes)
        updates
      end.delete_if do |key, value|
        value.empty?
      end
    end

    protected
    # Get all the push attributes that need to occur.
    def _pushes
      (new_record? && embedded_many? && !_parent.new_record?) ? { _path => raw_attributes } : {}
    end

    # Get all the attributes that need to be set.
    def _sets
      if changed? && !new_record?
        setters
      else
        embedded_one? && new_record? ? { _path => raw_attributes } : {}
      end
    end
  end
end
