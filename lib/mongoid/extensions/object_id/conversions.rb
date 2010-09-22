# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module ObjectId #:nodoc:
      module Conversions #:nodoc:

        def set(value)
          if value.is_a?(::String)
            BSON::ObjectId.from_string(value) unless value.blank?
          else
            value
          end
        end

        def get(value)
          value
        end

        # If the document is using BSON::ObjectIds the convert the argument to
        # either an object id or an array of them if the supplied argument is an
        # Array. Otherwise just return.
        #
        # Options:
        #  args: A +String+ or an +Array+ convert to +BSON::ObjectId+
        #  cast: A +Boolean+ define if we can or not cast to BSON::ObjectId.
        #        If false, we use the default type of args
        #
        # Example:
        #
        # <tt>Mongoid.cast_ids!("4ab2bc4b8ad548971900005c", true)</tt>
        # <tt>Mongoid.cast_ids!(["4ab2bc4b8ad548971900005c"])</tt>
        #
        # Returns:
        #
        # If using object ids:
        #   An +Array+ of +BSON::ObjectId+ of each element if params is an +Array+
        #   A +BSON::ObjectId+ from params if params is +String+
        # Otherwise:
        #   <tt>args</tt>
        def cast!(klass, args, cast = true)
          if !klass.using_object_ids? || args.is_a?(::BSON::ObjectId) || !cast
            return args
          end
          if args.is_a?(::String)
            ::BSON::ObjectId(args)
          elsif args.is_a?(::Array)
            args.map{ |a|
              a.is_a?(::BSON::ObjectId) ? a : ::BSON::ObjectId(a)
            }
          else
            args
          end
        end
      end
    end
  end
end
