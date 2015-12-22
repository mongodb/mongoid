# encoding: utf-8
module Mongoid
  class Criteria
    module Includable

      def add_inclusion(k, r)
        metadata = get_inclusion_metadata(k, r)
        raise Errors::InvalidIncludes.new(k, [ r ]) unless metadata
        inclusions.push(metadata) unless inclusions.include?(metadata)
      end

      def extract_relations_list(c, relations)
        relations.each do |r|
          if r.is_a?(Hash)
            extract_nested_relation(c, r)
          else
            add_inclusion(c, r)
          end
        end
      end

      def extract_nested_relation(c, relation)
        relation.each do |k, v|
          add_inclusion(c, k)
          if v.is_a?(Array)
            extract_relations_list(k, v)
          else
            add_inclusion(k, v)
          end
        end
      end

      def get_inclusion_metadata(k, n)
        if k.is_a?(Class)
          k.reflect_on_association(n)
        else
          k = k.to_s.classify.constantize
          k.reflect_on_association(n)
        end
      end
    end
  end
end
