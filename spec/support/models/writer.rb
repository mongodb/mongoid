# frozen_string_literal: true

class Writer
  include Mongoid::Document
  field :speed, type: Integer, default: 0

  embedded_in :canvas

  def write; end
end

require "support/models/pdf_writer"
require "support/models/html_writer"
