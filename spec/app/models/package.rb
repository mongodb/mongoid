# New Class created to isolate the test case of embedding with many referenced.
class Package
  include Mongoid::Document
  embeds_one :package_item, class_name: 'PackageItem', inverse_of: :testable
  has_and_belongs_to_many :package_containers
end