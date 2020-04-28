# frozen_string_literal: true
# encoding: utf-8

module Publication
  class Review
    include Mongoid::Document

    field :summary

    belongs_to :reviewable, polymorphic: true
    belongs_to :reviewer, polymorphic: true
    belongs_to :template
  end
end
