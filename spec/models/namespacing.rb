module Medical
  class Patient
    include Mongoid::Document
    field :name
    embeds_many :prescriptions, :class_name => "Medical::Prescription"
    references_and_referenced_in_many :doctors, :class_name => "Medical::Doctor"
  end
  class Prescription
    include Mongoid::Document
    field :name
  end
  class Doctor
    include Mongoid::Document
    field :name
    references_and_referenced_in_many :patients, :class_name => "Medical::Patient"
  end
end
