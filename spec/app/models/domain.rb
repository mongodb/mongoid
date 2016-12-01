class Domain
  include Mongoid::Document

  store_in database: 'default', skip_database_override: true

  field :name, type: String
end
