# frozen_string_literal: true

class Baby
  include Mongoid::Document
  embedded_in :kangaroo
end
