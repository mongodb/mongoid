# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:

      # Expands complex criterion into mongodb selectors.
      module CriteriaHelpers

        # Expand the complex criteria into a MongoDB compliant selector hash.
        #
        # @example Convert the criterion.
        #   {}.expand_complex_criteria
        #
        # @return [ Hash ] The mongo selector.
        #
        # @since 1.0.0
        def expand_complex_criteria
          {}.tap do |hsh|
            each_pair do |k, v|
              if k.respond_to?(:key) && k.respond_to?(:to_mongo_query)
                hsh[k.key] ||= {}
                v = v.expand_complex_criteria if v.is_a?(::Hash)
                hsh[k.key].merge!(k.to_mongo_query(v))
              else
                v.map!{|e| e.is_a?(::Hash) ? e.expand_complex_criteria : e } if v.is_a?(::Array)
                hsh[k] = v
              end
            end
          end
        end

        # Get the id attribute from this hash, whether it's prefixed with an
        # underscore or is a symbol.
        #
        # @example Extract the id.
        #   { :_id => 1 }.extract_id
        #
        # @return [ Object ] The value of the id.
        #
        # @since 2.3.2
        def extract_id
          self["id"] || self["_id"] || self[:id] || self[:_id]
        end
      end
    end
  end
end
