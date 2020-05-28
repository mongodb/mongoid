# frozen_string_literal: true
# encoding: utf-8

class Draft
  include Mongoid::Document

  field :text

  recursively_embeds_one

  index text: 1
end
