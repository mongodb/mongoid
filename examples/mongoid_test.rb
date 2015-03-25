require 'mongoid'
require 'mongoid/support/query_counter'
require 'minitest/autorun'
# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

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

class BugTest < Minitest::Test
  def test_query_count
    p = Person.create!(name: 'arthurnn')
    Post.create!(person: p)
    Post.create!(person: p)

    query_counter = count_queries do
      Person.includes(:posts).all.to_a
    end

    assert_equal 2, query_counter
  end
end
