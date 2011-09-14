class Post
  include Mongoid::Document
  include Mongoid::MultiParameterAttributes
  include Mongoid::Versioning
  include Mongoid::Timestamps

  field :title, :type => String
  field :content, :type => String
  field :rating, :type => Integer

  belongs_to :person
  belongs_to :author, :foreign_key => :author_id, :class_name => "User"
  has_and_belongs_to_many :tags
  has_many :videos, :validate => false

  scope :recent, where(:created_at => { "$lt" => Time.now, "$gt" => 30.days.ago })
  scope :posting, where(:content.in => [ "Posting" ])

  validates_format_of :title, :without => /\$\$\$/

  class << self
    def old
      where(:created_at => { "$lt" => 30.days.ago })
    end
  end
end
