require "mongoid/timestamps"
require "mongoid/timestamps/created"
require "mongoid/timestamps/updated"

module Mongoid

  module ShortTimestamps
    extend ActiveSupport::Concern
    include Timestamps::Created
    include Timestamps::Updated

    included do
      fields.delete :created_at.to_s
      remove_defaults :created_at.to_s
      fields.delete :updated_at.to_s
      remove_defaults :updated_at.to_s
      field :c_at, type: Time, as: :created_at
      field :u_at, type: Time, as: :updated_at
    end
  end

end
