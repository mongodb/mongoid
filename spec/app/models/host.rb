class Host
  include Mongoid::Document
  field :network_name, default: -> { network.name }
  belongs_to :network
end
