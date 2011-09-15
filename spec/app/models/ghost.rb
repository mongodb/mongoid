class Ghost
  include Mongoid::Document

  field :name, :type => String

  belongs_to :movie, :autosave => true
end
