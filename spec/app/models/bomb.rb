class Bomb
  include Mongoid::Document
  has_one :explosion, dependent: :delete, autobuild: true
end
