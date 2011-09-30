class WikiPage
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning

  field :title, :type => String
  field :transient_property, :type => String, :versioned => false
  max_versions 5

  has_many :comments, :dependent => :destroy, :validate => false
end
