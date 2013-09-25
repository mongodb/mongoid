class Phone
  include Mongoid::Document

  field :_id, type: String, overwrite: true, default: ->{ number }

  field :number
  embeds_one :country_code
  embedded_in :person
end
