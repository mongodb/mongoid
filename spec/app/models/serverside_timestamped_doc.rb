class ServersideTimestampedDoc
  include Mongoid::Document
  include Mongoid::Timestamps::Serverside

  field :title, type: String
end
