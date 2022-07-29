# frozen_string_literal: true

class IncUser
  include Mongoid::Document
  has_many :posts, class_name: 'IncPost'
  has_many :comments, class_name: 'IncComment'
end

class IncPost
  include Mongoid::Document
  belongs_to :user, class_name: 'IncUser'
  has_many :comments, class_name: 'IncComment'
end

class IncComment
  include Mongoid::Document
  belongs_to :posts, class_name: 'IncPost'
  belongs_to :user, class_name: 'IncUser'
  belongs_to :thread, class_name: 'IncThread'
end

class IncThread
  include Mongoid::Document
  has_many :comments, class_name: 'IncComment'
end

class IncBlog
  include Mongoid::Document

  has_and_belongs_to_many :posts, class_name: "IncBlogPost"
  belongs_to :highlighted_post, class_name: "IncBlogPost"
  belongs_to :pinned_post, class_name: "IncBlogPost"
end

class IncBlogPost
  include Mongoid::Document

  belongs_to :author, class_name: "IncAuthor"
end

class IncAuthor
  include Mongoid::Document
end

class IncPost
  include Mongoid::Document
  belongs_to :person, class_name: "IncPerson"
end

class IncPerson
  include Mongoid::Document
  has_many :posts, class_name: "IncPost"
  field :name
end
