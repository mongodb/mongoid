# frozen_string_literal: true

module Mongoid

  # This module contains the behavior for getting the various states a
  # document can transition through.
  module Stateful

    attr_writer :destroyed, :flagged_for_destroy, :previously_new_record

    def new_record=(new_value)
      @new_record ||= false
      if @new_record && !new_value
        @previously_new_record = true
      end
      @new_record = new_value
    end

    # Returns true if the +Document+ has not been persisted to the database,
    # false if it has. This is determined by the variable @new_record
    # and NOT if the object has an id.
    #
    # @example Is the document new?
    #   person.new_record?
    #
    # @return [ true | false ] True if new, false if not.
    def new_record?
      @new_record ||= false
    end

    # Returns true if this document was just created -- that is, prior to the last
    # save, the object didn't exist in the database and new_record? would have
    # returned true.
    #
    # @return [ true | false ] True if was just created, false if not.
    def previously_new_record?
      @previously_new_record ||= false
    end

    # Checks if the document has been saved to the database. Returns false
    # if the document has been destroyed.
    #
    # @example Is the document persisted?
    #   person.persisted?
    #
    # @return [ true | false ] True if persisted, false if not.
    def persisted?
      !new_record? && !destroyed?
    end

    # Checks if the document was previously saved to the database
    # but now it has been deleted.
    #
    # @return [ true | false ] True if was persisted but now destroyed,
    #   otherwise false.
    def previously_persisted?
      !new_record? && destroyed?
    end

    # Returns whether or not the document has been flagged for deletion, but
    # not destroyed yet. Used for atomic pulls of child documents.
    #
    # @example Is the document flagged?
    #   document.flagged_for_destroy?
    #
    # @return [ true | false ] If the document is flagged.
    def flagged_for_destroy?
      @flagged_for_destroy ||= false
    end
    alias :marked_for_destruction? :flagged_for_destroy?
    alias :_destroy :flagged_for_destroy?

    # Returns true if the +Document+ has been succesfully destroyed, and false
    # if it hasn't. This is determined by the variable @destroyed and NOT
    # by checking the database.
    #
    # @example Is the document destroyed?
    #   person.destroyed?
    #
    # @return [ true | false ] True if destroyed, false if not.
    def destroyed?
      @destroyed ||= false
    end

    # Determine if the document can be pushed.
    #
    # @example Is this pushable?
    #   person.pushable?
    #
    # @return [ true | false ] Is the document new and embedded?
    def pushable?
      new_record? &&
        embedded_many? &&
        _parent.persisted? &&
        !_parent.delayed_atomic_sets[atomic_path]
    end

    # Flags the document as readonly. Will cause a ReadonlyDocument error to be
    # raised if the document is attempted to be saved, updated or destroyed.
    #
    # @example Flag the document as readonly.
    #   document.readonly!
    #
    # @return [ true | false ] true if the document was successfully marked
    #   readonly, false otherwise.
    def readonly!
      if Mongoid.legacy_readonly
        Mongoid::Warnings.warn_legacy_readonly
        false
      else
        @readonly = true
      end
    end

    # Is the document readonly?
    #
    # @example Is the document readonly?
    #   document.readonly?
    #
    # @return [ true | false ] If the document is readonly.
    def readonly?
      if Mongoid.legacy_readonly
        __selected_fields != nil
      else
        @readonly ||= false
      end
    end

    # Determine if the document can be set.
    #
    # @example Is this settable?
    #   person.settable?
    #
    # @return [ true | false ] Is this document a new embeds one?
    def settable?
      new_record? && embedded_one? && _parent.persisted?
    end

    # Is the document updateable?
    #
    # @example Is the document updateable?
    #   person.updateable?
    #
    # @return [ true | false ] If the document is changed and persisted.
    def updateable?
      persisted? && changed?
    end

    private

    def reset_readonly
      self.__selected_fields = nil
    end
  end
end
