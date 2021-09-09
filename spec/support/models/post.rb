# frozen_string_literal: true

class Post
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :title, type: String
  field :content, type: String
  field :rating, type: Integer
  field :person_title, type: String, default: ->{ person.title if ivar(:person) }

  attr_accessor :before_add_called, :after_add_called, :before_remove_called, :after_remove_called

  belongs_to :person, counter_cache: true
  belongs_to :author, foreign_key: :author_id, class_name: "User"
  belongs_to :post_genre, foreign_key: :genre_id, counter_cache: true
  has_and_belongs_to_many :tags, before_add: :before_add_tag, after_add: :after_add_tag, before_remove: :before_remove_tag, after_remove: :after_remove_tag
  has_many :videos, validate: false
  has_many :roles, validate: false
  has_many :alerts

  belongs_to :posteable, polymorphic: true
  accepts_nested_attributes_for :posteable, autosave: true

  scope :recent, ->{ where(created_at: { "$lt" => Time.now, "$gt" => 30.days.ago }) }
  scope :posting, ->{ where(:content.in => [ "Posting" ]) }
  scope :open, ->{ where(title: "open") }

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
