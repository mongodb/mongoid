# frozen_string_literal: true
# rubocop:todo all

module Publication
  class Review
    include Mongoid::Document

    field :summary

    belongs_to :reviewable, polymorphic: true
    belongs_to :reviewer, polymorphic: true
    belongs_to :template
  end
end
