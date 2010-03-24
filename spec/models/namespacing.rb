module Medical
  class Patient
    include Mongoid::Document
    field :name
    embed_many :prescriptions, :class_name => "Medical::Prescription"
  end
  class Prescription
    include Mongoid::Document
    field :name
  end
end
