# frozen_string_literal: true

class Vertex
  include Mongoid::Document

  has_and_belongs_to_many :parents, inverse_of: :children, class_name: 'Vertex'
  has_and_belongs_to_many :children, inverse_of: :parents, class_name: 'Vertex'
end
