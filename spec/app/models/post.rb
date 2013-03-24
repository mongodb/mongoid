class Post
  include Mongoid::Document

  field :title, type: String
  field :content, type: String
  field :rating, type: Integer
  field :person_title, type: String, default: ->{ person.try(:title) }

  attr_accessor :before_add_called, :after_add_called, :before_remove_called, :after_remove_called

  belongs_to :person, counter_cache: true
  belongs_to :author, foreign_key: :author_id, class_name: "User"
  has_and_belongs_to_many :tags, before_add: :before_add_tag, after_add: :after_add_tag, before_remove: :before_remove_tag, after_remove: :after_remove_tag
  has_many :videos, validate: false
  has_many :roles, validate: false

  scope :recent, where(created_at: { "$lt" => Time.now, "$gt" => 30.days.ago })
  scope :posting, where(:content.in => [ "Posting" ])

  validates_format_of :title, without: /\$\$\$/

  def before_add_tag(tag)
    @before_add_called = true
  end

  def after_add_tag(tag)
    @after_add_called = true
  end

  def before_remove_tag(tag)
    @before_remove_called = true
  end

  def after_remove_tag(tag)
    @after_remove_called = true
  end

  class << self
    def old
      where(created_at: { "$lt" => 30.days.ago })
    end
  end
end
