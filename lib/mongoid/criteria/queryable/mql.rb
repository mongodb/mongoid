# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable
      module MQL
        def to_mql
          {
            find: collection.name,
            filter: selector
          }.merge(options)
        end
      end
    end
  end
end
