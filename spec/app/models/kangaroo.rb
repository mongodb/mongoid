class Kangaroo
  include Mongoid::Document
  embeds_one :baby
end