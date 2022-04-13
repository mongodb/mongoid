# frozen_string_literal: true

class BTMArticle
  include Mongoid::Document
  has_many :comments, class_name: "BTMComment"
end

class BTMComment
  include Mongoid::Document
  belongs_to :article, class_name: "BTMArticle", required: false
end
