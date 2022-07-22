# frozen_string_literal: true

module Mongoid
  module Association

    module Options

      # Returns the name of the parent to a polymorphic child.
      #
      # @return [ String | Symbol ] The name.
      def as
        @options[:as]
      end

      # Specify what happens to the associated object when the owner is destroyed.
      #
      # @return [ String ] The dependent option.
      def dependent
        @options[:dependent]
      end

      # The custom sorting options on the association.
      #
      # @return [ Criteria::Queryable::Key ] The custom sorting options.
      def order
        @options[:order]
      end

      # Whether to index the primary or foreign key field.
      #
      # @return [ true | false ]
      def indexed?
        @indexed ||= !!@options[:index]
      end

      # Whether the association is autobuilding.
      #
      # @return [ true | false ]
      def autobuilding?
        !!@options[:autobuild]
      end

      # Is the association cyclic.
      #
      # @return [ true | false ] Whether the association is cyclic.
      def cyclic?
        !!@options[:cyclic]
      end

      # The name the owning object uses to refer to this association.
      #
      # @return [ String ] The inverse_of option.
      def inverse_of
        @options[:inverse_of]
      end

      # Mongoid assumes that the field used to hold the primary key of the association is id.
      # You can override this and explicitly specify the primary key with the :primary_key option.
      #
      # @return [ Symbol | String ] The primary key.
      def primary_key
        @primary_key ||= @options[:primary_key] ? @options[:primary_key].to_s : Relatable::PRIMARY_KEY_DEFAULT
      end

      # Options to save any loaded members and destroy members that are marked for destruction
      # when the parent object is saved.
      #
      # @return [ true | false ] The autosave option.
      def autosave
        !!@options[:autosave]
      end
      alias :autosave? :autosave

      # Whether the association is counter-cached.
      #
      # @return [ true | false ]
      def counter_cached?
        !!@options[:counter_cache]
      end

      # Whether this association is polymorphic.
      #
      # @return [ true | false ] Whether the association is polymorphic.
      def polymorphic?; false; end

      # Whether the association has callbacks cascaded down from the parent.
      #
      # @return [ true | false ] Whether callbacks are cascaded.
      def cascading_callbacks?
        !!@options[:cascade_callbacks]
      end

      # The store_as option.
      #
      # @return [ nil ] Default is nil.
      def store_as; end

      # Whether the association has forced nil inverse (So no foreign keys are saved).
      #
      # @return [ false ] Default is false.
      def forced_nil_inverse?; false; end

      # The field for saving the associated object's type.
      #
      # @return [ nil ] Default is nil.
      def type; end

      # The field for saving the associated object's type.
      #
      # @return [ nil ] Default is nil.
      def touch_field
        @touch_field ||= options[:touch] if (options[:touch].is_a?(String) || options[:touch].is_a?(Symbol))
      end

      private

      def touchable?
        !!@options[:touch]
      end
    end
  end
end
