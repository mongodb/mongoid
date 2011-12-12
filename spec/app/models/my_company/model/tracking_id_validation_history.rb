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
