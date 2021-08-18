# frozen_string_literal: true

class Seo
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, type: String

  embedded_in :seo_tags, polymorphic: true
end
