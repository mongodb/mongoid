class Employee
  include Mongoid::Document
  field :job_name, default: -> { job.name }
  embedded_in :job
end
