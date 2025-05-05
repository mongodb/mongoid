# frozen_string_literal: true

require 'mongoid/model_resolver'

module Mongoid
  # Implements the "identify_as" interface (for specifying type aliases
  # for document classes).
  module Identifiable
    extend ActiveSupport::Concern

    class_methods do
      # Specifies aliases that may be used to identify this document
      # class in polymorphic situations. By default, classes are identified
      # by their class names, but alternative aliases may be used instead,
      # if desired.
      #
      # @param [ Array<String | Symbol> ] aliases the list of aliases to
      #   assign to this class.
      # @param [ Mongoid::ModelResolver::Interface | Symbol | :default ] resolver the
      #   resolver instance to use when registering the type. If :default, the default
      #   `ModelResolver` instance will be used. If any other symbol, it must identify a
      #   previously registered ModelResolver instance.
      def identify_as(*aliases, resolver: :default)
        Mongoid::ModelResolver.resolver(resolver).register(self, *aliases)
      end
    end
  end
end
