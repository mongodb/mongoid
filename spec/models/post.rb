class Tag
  include Mongoid::Document
  field :text
  belongs_to_related :post, :stored_as => :array
end

class Post
  include Mongoid::Document
  include Mongoid::Versioning
  include Mongoid::Timestamps
  field :title
  belongs_to_related :person

  has_many_related :tags, :stored_as => :array

  named_scope :recent, where(:created_at => { "$lt" => Time.now, "$gt" => 30.days.ago })

  class << self
    def old
      where(:created_at => { "$lt" => 30.days.ago })
    end
  end
end
