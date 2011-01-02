# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This is the superclass for one to one relations and defines the common
    # behaviour or those proxies.
    class One < Proxy

      # Substitutes the supplied target documents for the existing document
      # in the relation.
      #
      # @example Substitute the new document.
      #   person.name.substitute(new_name)
      #
      # @param [ Documetn ] other A document to replace the target.
      #
      # @return [ Document, nil ] The relation or nil.
      #
      # @since 2.0.0.rc.1
      def substitute(new_target, building = nil)
        old_target = target
        tap do |relation|
          relation.target = new_target
          new_target ? bind(building) : (unbind(old_target) and return nil)
        end
      end
    end
  end
end
