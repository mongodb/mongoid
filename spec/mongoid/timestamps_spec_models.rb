# frozen_string_literal: true

module TimestampsSpec
  module Touch
    class User
      include Mongoid::Document
      include Mongoid::Timestamps

      has_and_belongs_to_many :addresses, class_name: "TimestampsSpec::Touch::Address"
      has_many :accounts, class_name: "TimestampsSpec::Touch::Account"
      has_one :pet, class_name: "TimestampsSpec::Touch::Pet"
    end

    class Address
      include Mongoid::Document
      include Mongoid::Timestamps

      has_and_belongs_to_many :users, class_name: "TimestampsSpec::Touch::User"
    end

    class Account
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :user, required: false, touch: true, class_name: "TimestampsSpec::Touch::User"
    end

    class Pet
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :user, required: false, touch: true, class_name: "TimestampsSpec::Touch::User"
    end
  end

  module NoTouch
    class User
      include Mongoid::Document
      include Mongoid::Timestamps

      has_and_belongs_to_many :addresses, class_name: "TimestampsSpec::NoTouch::Address"
      has_many :accounts, class_name: "TimestampsSpec::NoTouch::Account"
      has_one :pet, class_name: "TimestampsSpec::NoTouch::Pet"
    end

    class Address
      include Mongoid::Document
      include Mongoid::Timestamps

      has_and_belongs_to_many :users, class_name: "TimestampsSpec::NoTouch::User"
    end

    class Account
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :user, required: false, touch: false, class_name: "TimestampsSpec::NoTouch::User"
    end

    class Pet
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :user, required: false, touch: false, class_name: "TimestampsSpec::NoTouch::User"
    end
  end
end
