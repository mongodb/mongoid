# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:

    # This module defines criteria behavior for deleting or destroying
    # documents.
    module Destructive

      # Delete all documents in the database that match the criteria.
      #
      # @example Delete all matching documents.
      #   Person.where(:title => "Sir").and(:age.gt => 5).delete_all
      #
      # @return [ Integer ] The number of documents deleted.
      #
      # @since 2.0.0.rc.1
      def delete_all
        context.delete_all
      end
      alias :delete :delete_all

      # Destroy all documents in the database that match the criteria. Will run
      # the destruction callbacks on each document as well.
      #
      # @example Destroy all matching documents.
      #   Person.where(:title => "Sir").and(:age.gt => 5).destroy_all
      #
      # @return [ Integer ] The number of documents destroyed.
      #
      # @since 2.0.0.rc.1
      def destroy_all
        context.destroy_all
      end
      alias :destroy :destroy_all
    end
  end
end
