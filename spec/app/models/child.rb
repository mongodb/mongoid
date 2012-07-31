class Child
  include Mongoid::Document
  embedded_in :parent, inverse_of: :childable, polymorphic: true
end
