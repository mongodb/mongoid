class Filesystem
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  embedded_in :server
end
