class Page
  include Mongoid::Document
  embedded_in :quiz
  embeds_many :page_questions

  embedded_in :book, touch: true
  embeds_many :notes
  field :content, :type => String
  field :page_number, :type => Integer

  after_initialize do
    if self[:content]
      self[:text] = self[:content]
      self.remove_attribute(:content)
    end
  end

  before_validation do
    self.page_number = 1 unless self.page_number
  end
end
