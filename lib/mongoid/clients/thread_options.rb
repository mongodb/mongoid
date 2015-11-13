# encoding: utf-8
module Mongoid
  module Clients
    module ThreadOptions
      extend ActiveSupport::Concern

      module ClassMethods

        def client_name
          Threaded.client_override || super
        end

        def database_name
          Threaded.database_override || super
        end
      end
    end
  end
end
