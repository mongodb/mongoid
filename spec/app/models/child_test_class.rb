class ChildTestClass
  include Mongoid::Document

  embedded_in :parent_test_class, inverse_of: :child_test_one
  embedded_in :parent_test_class, inverse_of: :child_test_two

  field :value, type: String
end
