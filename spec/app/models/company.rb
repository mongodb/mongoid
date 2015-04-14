class Company
  include Mongoid::Document

  embeds_many :staffs
end
