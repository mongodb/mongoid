class Job
  include Mongoid::Document
  field :name
  embeds_many :employees
end
