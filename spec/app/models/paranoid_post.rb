class ParanoidPost
  include Mongoid::Document
  include Mongoid::Versioning
  include Mongoid::Paranoia

  max_versions 2

  field :title, type: String

  attr_accessor :after_destroy_called, :before_destroy_called

  belongs_to :person

  has_and_belongs_to_many :tags
  has_many :authors, dependent: :delete
  has_many :titles, dependent: :restrict

  scope :recent, where(created_at: { "$lt" => Time.now, "$gt" => 30.days.ago })

  before_destroy :before_destroy_stub
  after_destroy :after_destroy_stub

  def before_destroy_stub
    self.before_destroy_called = true
  end

  def after_destroy_stub
    self.after_destroy_called = true
  end

  class << self
    def old
      where(created_at: { "$lt" => 30.days.ago })
    end
  end
end
