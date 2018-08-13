# frozen_string_literal: true

class Draft
  include Mongoid::Document

  field :text

  recursively_embeds_one

  index text: 1
end
