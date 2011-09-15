class WikiPage
  include Mongoid::Document
  include Mongoid::Versioning
  field :title, :type => String
  field :transient_property, :type => String, :versioned => false
  max_versions 5
end
