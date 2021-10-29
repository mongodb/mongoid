# frozen_string_literal: true

module Publication
  class Encyclopedia
    include Mongoid::Document

    field :title, type: String

    has_many :reviews, class_name: 'Publication::Review', as: :reviewable
  end
end
