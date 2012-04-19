# encoding: utf-8
module Mongoid
  module Extensions
    module ObjectId

      def __evolve_object_id__
        self
      end

      module ClassMethods

        def evolve(object)
          object.__evolve_object_id__
        end

        def mongoize(object)
          evolve(object)
        end
      end
    end
  end
end

Moped::BSON::ObjectId.__send__(:include, Mongoid::Extensions::ObjectId)
Moped::BSON::ObjectId.__send__(:extend, Mongoid::Extensions::ObjectId::ClassMethods)
