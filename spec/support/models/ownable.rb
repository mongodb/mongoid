# frozen_string_literal: true
# rubocop:todo all

module Ownable
  extend ActiveSupport::Concern
  included do
    belongs_to :user
  end
end
