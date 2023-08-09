# frozen_string_literal: true
# rubocop:todo all

class Browser < Canvas
  field :version, type: Integer
  def render; end
end

require "support/models/firefox"
