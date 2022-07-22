# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable
      module Extensions

        # This module contains additional regex behavior.
        module Regexp

          # Is the object a regexp?
          #
          # @example Is the object a regex?
          #   /\A[123]/.regexp?
          #
          # @return [ true ] Always true.
          def regexp?; true; end

          module ClassMethods

            # Evolve the object into a regex.
            #
            # @example Evolve the object to a regex.
            #   Regexp.evolve("\A[123]")
            #
            # @param [ Regexp | String ] object The object to evolve.
            #
            # @return [ Regexp ] The evolved regex.
            def evolve(object)
              __evolve__(object) do |obj|
                mongoize(obj)
              end
            end
          end

          module Raw_

            # Is the object a regexp?
            #
            # @example Is the object a regex?
            #   bson_raw_regexp.regexp?
            #
            # @return [ true ] Always true.
            def regexp?; true; end

            module ClassMethods

              # Evolve the object into a raw bson regex.
              #
              # @example Evolve the object to a regex.
              #   BSON::Regexp::Raw.evolve("\\A[123]")
              #
              # @param [ BSON::Regexp::Raw | String ] object The object to evolve.
              #
              # @return [ BSON::Regexp::Raw ] The evolved raw regex.
              def evolve(object)
                __evolve__(object) do |obj|
                  obj.is_a?(String) ? BSON::Regexp::Raw.new(obj) : obj
                end
              end
            end
          end
        end
      end
    end
  end
end

::Regexp.__send__(:include,Mongoid::Criteria::Queryable::Extensions::Regexp)
::Regexp.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::Regexp::ClassMethods)
BSON::Regexp::Raw.__send__(:include,Mongoid::Criteria::Queryable::Extensions::Regexp::Raw_)
BSON::Regexp::Raw.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::Regexp::Raw_::ClassMethods)
