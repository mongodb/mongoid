# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasOneThrough
        # Two-query eager preloader for has_one :through associations.
        class Eager < Association::Eager
          private

          def preload
            @docs.each { |d| set_relation(d, nil) }

            through_assoc = @association.through_association
            source_assoc  = @association.source_association

            owner_pk   = through_assoc.primary_key
            through_fk = through_assoc.foreign_key

            owner_ids = @docs.filter_map { |d| d.public_send(owner_pk) }.uniq
            return if owner_ids.empty?

            intermediates = through_assoc.klass.where(through_fk => { '$in' => owner_ids }).to_a
            intermediate_to_target = build_intermediate_to_target(intermediates, through_fk, source_assoc)

            @docs.each do |doc|
              owner_key_val = doc.public_send(owner_pk)
              target = intermediate_to_target[owner_key_val]
              proxy = target ? HasOneThrough::Proxy.new(doc, target, @association) : nil
              doc.set_relation(@association.name, proxy) unless doc.blank?
            end
          end

          def build_intermediate_to_target(intermediates, through_fk, source_assoc)
            if source_assoc.stores_foreign_key?
              # FK is on the intermediate (e.g. belongs_to :store => intermediate.store_id)
              source_fk_values = intermediates.filter_map { |i| i.public_send(source_assoc.foreign_key) }.uniq
              targets = source_assoc.klass.where(source_assoc.primary_key => { '$in' => source_fk_values }).to_a
              targets_by_key = targets.index_by { |t| t.public_send(source_assoc.primary_key) }
              intermediates.to_h do |i|
                [ i.public_send(through_fk), targets_by_key[i.public_send(source_assoc.foreign_key)] ]
              end
            else
              # FK is on the source (e.g. has_one :store => store.franchise_id)
              source_pk = source_assoc.primary_key
              intermediate_pks = intermediates.filter_map { |i| i.public_send(source_pk) }.uniq
              targets = source_assoc.klass.where(source_assoc.foreign_key => { '$in' => intermediate_pks }).to_a
              targets_by_fk = targets.index_by { |t| t.public_send(source_assoc.foreign_key) }
              intermediates.index_by { |i| i.public_send(through_fk) }.transform_values do |i|
                targets_by_fk[i.public_send(source_pk)]
              end
            end
          end

          # Required by the base class contract. Not called by this preloader
          # because preload manages document traversal directly without using
          # the grouped_docs / keys_from_docs machinery from the base class.
          def group_by_key
            @association.through_association.primary_key
          end
        end
      end
    end
  end
end
