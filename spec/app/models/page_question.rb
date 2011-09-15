class PageQuestion
  include Mongoid::Document
  embedded_in :page
end
