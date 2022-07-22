# frozen_string_literal: true

module Mongoid

  # This module contains the behavior of Mongoid's clone/dup of documents.
  module Equality
    # Leave the current contents of this module outside of InstanceMethods
    # to prevent cherry picking conflicts. For now...
    extend ActiveSupport::Concern

    # Default comparison is via the string version of the id.
    #
    # @example Compare two documents.
    #   person <=> other_person
    #
    # @param [ Document ] other The document to compare with.
    #
    # @return [ Integer ] -1, 0, 1.
    def <=>(other)
      attributes["_id"].to_s <=> other.attributes["_id"].to_s
    end

    # Performs equality checking on the document ids. For more robust
    # equality checking please override this method.
    #
    # @example Compare for equality.
    #   document == other
    #
    # @param [ Document | Object ] other The other object to compare with.
    #
    # @return [ true | false ] True if the ids are equal, false if not.
    def ==(other)
      self.class == other.class &&
          attributes["_id"] == other.attributes["_id"]
    end

    # Performs class equality checking.
    #
    # @example Compare the classes.
    #   document === other
    #
    # @param [ Document | Object ] other The other object to compare with.
    #
    # @return [ true | false ] True if the classes are equal, false if not.
    def ===(other)
      if Mongoid.legacy_triple_equals
        other.class == Class ? self.class === other : self == other
      else
        super
      end
    end

    # Delegates to ==. Used when needing checks in hashes.
    #
    # @example Perform equality checking.
    #   document.eql?(other)
    #
    # @param [ Document | Object ] other The object to check against.
    #
    # @return [ true | false ] True if equal, false if not.
    def eql?(other)
      self == (other)
    end

    module ClassMethods
      # Performs class equality checking.
      #
      # @example Compare the classes.
      #   document === other
      #
      # @param [ Document | Object ] other The other object to compare with.
      #
      # @return [ true | false ] True if the classes are equal, false if not.
      def ===(other)
        if Mongoid.legacy_triple_equals
          other.class == Class ? self <= other : other.is_a?(self)
        else
          other.is_a?(self)
        end
      end
    end
  end
end
