# encoding: utf-8
module Mongoid
  module Relations
    module Touchable
      extend ActiveSupport::Concern

      module ClassMethods

        # Add the metadata to the touchable relations if the touch option was
        # provided.
        #
        # @example Add the touchable.
        #   Model.touchable(meta)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @return [ Class ] The model class.
        #
        # @since 3.0.0
        def touchable(metadata)
          if metadata.touchable?
            name = metadata.name
            method_name = define_relation_touch_method(name)
            after_create method_name
            after_destroy method_name
            after_touch method_name
          end
          self
        end

        private

        # Define the method that will get called for touching belongs_to
        # relations.
        #
        # @api private
        #
        # @example Define the touch relation.
        #   Model.define_relation_touch_method(:band)
        #
        # @param [ Symbol ] name The name of the relation.
        #
        # @since 3.1.0
        #
        # @return [ Symbol ] The method name.
        def define_relation_touch_method(name)
          method_name = "touch_#{name}_after_create_or_destroy"
          class_eval <<-TOUCH
            def #{method_name}
              without_autobuild do
                relation = __send__(:#{name})
                relation.touch if relation
              end
            end
          TOUCH
          method_name.to_sym
        end
      end
    end
  end
end
