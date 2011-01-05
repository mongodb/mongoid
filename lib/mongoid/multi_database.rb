module Mongoid::MultiDatabase
  extend ActiveSupport::Concern

  module ClassMethods

    def database; @database end
    def set_database(name)
      @database = name.to_s
    end
  end
end
