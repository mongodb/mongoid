module Mongoid
  module Sessions
    module ThreadOptions
      extend ActiveSupport::Concern

      module ClassMethods

        def session_name
          Threaded.session_override || super
        end

        def database_name
          Threaded.database_override || super
        end
      end
    end
  end
end
