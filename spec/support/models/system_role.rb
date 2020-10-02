class SystemRole
 include Mongoid::Document

  # NOTE: this model is for test purposes only. It is not recommended that you
  # store Mongoid documents in system collections.
  store_in collection: "system.roles", database: "admin"
end
