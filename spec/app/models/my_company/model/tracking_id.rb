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
