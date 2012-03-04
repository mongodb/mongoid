# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Symbol

      REVERSALS = {
        asc: :desc,
        ascending: :descending,
        desc: :asc,
        descending: :ascending
      }

      # Get the inverted sorting option.
      #
      # @example Get the inverted option.
      #   :asc.invert
      #
      # @return [ String ] The string inverted.
      def invert
        REVERSALS[self]
      end

      # Define all the necessary methods on symbol to support Mongoid's
      # complex criterion.
      #
      # @example A greater than criterion.
      #   :field.gt => 5
      #
      # @return [ Criterion::Complex ] The criterion.
      #
      # @since 1.0.0
      [
        "all",
        "asc",
        "ascending",
        "desc",
        "descending",
        "exists",
        "gt",
        "gte",
        "in",
        "lt",
        "lte",
        "mod",
        "ne",
        "near",
        "not",
        "nin",
        "within",
        ["count", "size"],
        ["matches","elemMatch"] ].each do |oper|
        m, oper = oper
        oper = m unless oper
        class_eval <<-OPERATORS
          def #{m}
            Criterion::Complex.new(:key => self, :operator => "#{oper}")
          end
        OPERATORS
      end

      # Is the symbol a valid value for a Mongoid id?
      #
      # @example Is the string an id value?
      #   :_id.mongoid_id?
      #
      # @return [ true, false ] If the symbol is :id or :_id.
      #
      # @since 2.3.1
      def mongoid_id?
        to_s =~ /^(|_)id$/
      end
    end
  end
end

::Symbol.__send__(:include, Mongoid::Extensions::Symbol)
