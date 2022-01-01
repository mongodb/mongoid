# frozen_string_literal: true

class Browser < Canvas
  field :version, type: :integer
  def render; end
end

require "support/models/firefox"
