# encoding: utf-8
module Mongoid
  module Relations
    module Cascading
      class RestrictWithError < Base

        # This cascade does not delete the document if it has children, this will
        # add a error on the document.
        #
        # @example Restrict with error
        #   strategy.cascade
        #
        # @since 4.0.2
        def cascade
          unless relation.blank?
            record = metadata.name
            relation_name = metadata.relation.to_s.demodulize.underscore
            document.errors.add(:base, :"restrict_dependent_destroy.#{relation_name}",
                                record: record)
            throw :skip_delete
          end
        end
      end
    end
  end
end

