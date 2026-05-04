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

            # Step 1: load all intermediate records keyed by their FK to owner
            owner_pk   = through_assoc.primary_key
            through_fk = through_assoc.foreign_key

            owner_ids = @docs.filter_map { |d| d.public_send(owner_pk) }.uniq
            return if owner_ids.empty?

            intermediates = through_assoc.klass.where(through_fk => { '$in' => owner_ids }).to_a

            # Step 2: load all source records
            if source_assoc.stores_foreign_key?
              # FK is on the intermediate (e.g. belongs_to :store => intermediate.store_id)
              source_fk_values = intermediates.filter_map { |i| i.public_send(source_assoc.foreign_key) }.uniq
              targets = source_assoc.klass.where(source_assoc.primary_key => { '$in' => source_fk_values }).to_a
              targets_by_key = targets.index_by { |t| t.public_send(source_assoc.primary_key) }
              intermediate_to_target = intermediates.to_h do |i|
                [ i.public_send(through_fk), targets_by_key[i.public_send(source_assoc.foreign_key)] ]
              end
            else
              # FK is on the source (e.g. has_one :store => store.franchise_id)
              intermediate_pks = intermediates.filter_map { |i| i.public_send(through_assoc.primary_key) }.uniq
              targets = source_assoc.klass.where(source_assoc.foreign_key => { '$in' => intermediate_pks }).to_a
              targets_by_fk = targets.index_by { |t| t.public_send(source_assoc.foreign_key) }
              intermediate_by_owner_fk = intermediates.index_by { |i| i.public_send(through_fk) }
              intermediate_to_target = intermediate_by_owner_fk.transform_values do |i|
                targets_by_fk[i.public_send(through_assoc.primary_key)]
              end
            end

            # Step 3: set relation on each owner doc
            @docs.each do |doc|
              owner_key_val = doc.public_send(owner_pk)
              set_relation(doc, intermediate_to_target[owner_key_val])
            end
          end

          def group_by_key
            @association.through_association.primary_key
          end
        end
      end
    end
  end
end
