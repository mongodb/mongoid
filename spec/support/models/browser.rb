# frozen_string_literal: true

class Browser < Canvas
  field :version, type: Integer
  def render; end
end

require "support/models/firefox"
