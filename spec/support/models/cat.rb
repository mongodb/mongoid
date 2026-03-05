# frozen_string_literal: true
# rubocop:todo all

class Cat
  include Mongoid::Document

  field :name

  belongs_to :person, primary_key: :username

end
