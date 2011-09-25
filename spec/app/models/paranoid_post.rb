class ParanoidPost
  include Mongoid::Document
  include Mongoid::Versioning
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  field :title
  belongs_to :person

  has_and_belongs_to_many :tags

  named_scope :recent, where(:created_at => { "$lt" => Time.now, "$gt" => 30.days.ago })

  class << self
    def old
      where(:created_at => { "$lt" => 30.days.ago })
    end
  end
end
