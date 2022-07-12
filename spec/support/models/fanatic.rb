# frozen_string_literal: true

class Fanatic
  include Mongoid::Document
  field :age, type: Integer

  embedded_in :band
end
