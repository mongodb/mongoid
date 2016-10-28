class Baby
  include Mongoid::Document
  embedded_in :kangaroo
end
