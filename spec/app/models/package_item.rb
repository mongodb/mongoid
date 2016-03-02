class PackageItem
  include Mongoid::Document
  embedded_in :packagable, polymorphic: true
end