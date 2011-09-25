# These models are spcific to test for Github #313.
module MyCompany
  module Model
    class TrackingId
      include Mongoid::Document
      include Mongoid::Timestamps
      store_in :tracking_ids
      embeds_many :validation_history, :class_name => "MyCompany::Model::TrackingIdValidationHistory"
    end
  end
end

module MyCompany
  module Model
    # A TrackingId validation state change
    class TrackingIdValidationHistory
      include Mongoid::Document
      field :old_state, :type => String
      field :new_state, :type => String
      field :when_changed, :type => DateTime
      attr_protected :_id
      embedded_in :tracking_id, :class_name => "MyCompany::Model::TrackingId"
    end
  end
end
