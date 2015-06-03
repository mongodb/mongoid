# encoding: utf-8
module Mongoid
  module Clients
    module ThreadOptions
      extend ActiveSupport::Concern

      module ClassMethods
        extend Gem::Deprecate

        def client_name
          Threaded.client_override || super
        end
        alias :session_name :client_name
        deprecate :session_name, :client_name, 2015, 12

        def database_name
          Threaded.database_override || super
        end
      end
    end
  end
end
