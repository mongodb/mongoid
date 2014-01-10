class Edit
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  embedded_in :wiki_page, touch: true
end
