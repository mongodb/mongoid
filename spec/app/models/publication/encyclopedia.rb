# frozen_string_literal: true
# encoding: utf-8

module Publication
  class Encyclopedia
    include Mongoid::Document

    field :title, type: String

    has_many :reviews, class_name: 'Publication::Review', as: :reviewable
  end
end
