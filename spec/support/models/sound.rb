# frozen_string_literal: true

class Sound
  include Mongoid::Document
  field :active, type: :boolean
  default_scope ->{ where(active: true) }
end
