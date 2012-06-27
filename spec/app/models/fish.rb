class Fish
  include Mongoid::Document
  include Mongoid::Paranoia

  def self.fresh
    where(fresh: true)
  end
end
