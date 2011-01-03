class WikiPage
  include Mongoid::Document
  include Mongoid::Versioning
  field :title, :type => String
  max_versions 5
end
