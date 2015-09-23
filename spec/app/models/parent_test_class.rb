class ParentTestClass
  include Mongoid::Document

  embeds_one :child_test_one, cascade_callbacks: true, class_name: "ChildTestClass"
  embeds_one :child_test_two, cascade_callbacks: true, class_name: "ChildTestClass"
end
