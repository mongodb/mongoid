# encoding: utf-8
require "mongoid/relations/accessors"
require "mongoid/relations/proxy"
require "mongoid/relations/one_to_many"
require "mongoid/relations/one_to_one"
require "mongoid/relations/embedded/builders"
require "mongoid/relations/embedded/in"
require "mongoid/relations/embedded/many"
require "mongoid/relations/embedded/one"
require "mongoid/relations/metadata"
require "mongoid/relations/macros"

module Mongoid # :nodoc:
  module Relations #:nodoc:
    extend ActiveSupport::Concern
    include Accessors
    include Embedded::Builders
    include Macros

    included do
      cattr_accessor :embedded
      self.embedded = false

      # Convenience methods for the instance to know about attributes that
      # are located at the class level.
      delegate \
        :embedded,
        :embedded?, :to => "self.class"
    end

    module ClassMethods #:nodoc:

      # Specifies whether or not the class is an embedded document.
      #
      # Example:
      #
      # <tt>Address.embedded?</tt>
      #
      # Returns:
      #
      # true if embedded, false if not.
      def embedded?
        !!embedded
      end
    end
  end
end
