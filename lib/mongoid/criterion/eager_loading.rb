# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module EagerLoading
      # EagerLoading criterion are used when eager loading the associations.
      #
      # Example:
      #
      # <tt>criteria.includes(:user)</tt>
      #
      # <tt>criteria.includes(:user, :post)</tt>
      #
      # Returns: <tt>self</tt>
      attr_accessor :eager_loadings

      def includes(*options)
        @eager_loadings = options
      end

      def preload(documents)
        ids = documents.collect(&:id)
        foreign_key_name = "#{documents.first.class.to_s.underscore}_id"
        @eager_loadings.each do |eager_loading|
          eager_associations = eager_loading.to_s.camelize.constantize.where(foreign_key_name.to_sym.in => ids)
          documents.each do |document|
            document.send(eager_loading, eager_associations.select { |eager_association| eager_association.send(foreign_key_name) == document.id })
          end
        end
      end
    end
  end
end
