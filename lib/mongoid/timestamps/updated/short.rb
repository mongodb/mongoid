# encoding: utf-8
module Mongoid
  module Timestamps
    module Updated

      # Adds a created_at timestamp to the document, but it is stored as c_at
      # with a created_at alias.
      module Short
        extend ActiveSupport::Concern

        included do
          include Updated
          fields.delete("updated_at")
          field :u_at, type: Time, as: :updated_at
        end
      end
    end
  end
end
