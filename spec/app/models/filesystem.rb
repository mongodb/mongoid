class Filesystem
  include Mongoid::Document
  embedded_in :server
end
