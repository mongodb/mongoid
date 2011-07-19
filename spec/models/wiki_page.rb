class WikiPage
  include Mongoid::Document
  include Mongoid::Versioning
  field :title, :type => String
  field :transient_property, :type => String
  max_versions 5
  versions_exclude :transient_property
end
