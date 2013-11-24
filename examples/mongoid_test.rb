require 'mongoid'
require 'mongoid/support/query_counter'

Mongoid.configure.connect_to("mongoid_test")

def count_queries(&block)
  query_counter = Mongoid::QueryCounter.new
  query_counter.instrument(&block)
  query_counter.events.size
end

class Post
  include Mongoid::Document
  belongs_to :person
end

class Person
  include Mongoid::Document
  has_many :posts
  field :name
end

p = Person.create!(name: 'arthurnn')
post1 = Post.create!(person: p)
post2 = Post.create!(person: p)

query_counter = count_queries do
  Person.includes(:posts).all.to_a
end

p query_counter
