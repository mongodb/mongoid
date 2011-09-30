class WikiPage
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning

  field :title, :type => String
  field :transient_property, :type => String, :versioned => false
  max_versions 5

  has_many :comments, :dependent => :destroy, :validate => false
  has_many :child_pages, :class_name => "WikiPage", :dependent => :delete
  belongs_to :parent_pages, :class_name => "WikiPage"
end
