# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:

    # This module defines criteria behavior for modifying documents.
    module Modification

      # Very basic update that will perform a simple atomic $set of the
      # attributes provided in the hash. Can be expanded to later for more
      # robust functionality.
      #
      # @example Update all matching documents.
      #   Person.where(:title => "Mam").update_all(:title => "Sir")
      #
      # @param [ Hash ] attributes The sets to perform.
      #
      # @since 2.0.0.rc.4
      def update_all(attributes = {})
        context.update_all(attributes)
      end
      alias :update :update_all
    end
  end
end
