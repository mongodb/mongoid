# frozen_string_literal: true
# encoding: utf-8

class Browser < Canvas
  field :version, type: Integer
  def render; end
end

require "app/models/firefox"
