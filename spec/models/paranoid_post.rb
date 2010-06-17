class ParanoidPost
  include Mongoid::Document
  include Mongoid::Versioning
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  field :title
  referenced_in :person

  references_many :tags, :stored_as => :array

  named_scope :recent, where(:created_at => { "$lt" => Time.now, "$gt" => 30.days.ago })

  class << self
    def old
      where(:created_at => { "$lt" => 30.days.ago })
    end
  end
end
