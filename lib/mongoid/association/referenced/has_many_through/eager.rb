# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasManyThrough
        # Two-query eager preloader for has_many :through associations.
        class Eager < Association::Eager
          private

          def preload
            @docs.each { |d| set_relation(d, []) }

            through_assoc = @association.through_association
            source_assoc  = @association.source_association

            owner_pk   = through_assoc.primary_key
            through_fk = through_assoc.foreign_key

            owner_ids = @docs.filter_map { |d| d.public_send(owner_pk) }.uniq
            return if owner_ids.empty?

            # Step 1: load all intermediate records
            intermediates = through_assoc.klass
                                         .where(through_fk => { '$in' => owner_ids })
                                         .to_a

            # Step 2: map owner FK values to arrays of target docs
            targets_by_owner_fk = build_targets_map(intermediates, through_fk, source_assoc)

            # Step 3: set relation on each owner doc
            @docs.each do |doc|
              key_val = doc.public_send(owner_pk)
              set_relation(doc, targets_by_owner_fk[key_val] || [])
            end
          end

          # Build a Hash mapping each owner FK value to an array of target docs.
          # Uses two different strategies depending on where the FK lives.
          def build_targets_map(intermediates, through_fk, source_assoc)
            if source_assoc.stores_foreign_key?
              fk_on_intermediate_targets_map(intermediates, through_fk, source_assoc)
            else
              fk_on_source_targets_map(intermediates, through_fk, source_assoc)
            end
          end

          # FK is on the intermediate (e.g. appointment.patient_id -> belongs_to :patient).
          def fk_on_intermediate_targets_map(intermediates, through_fk, source_assoc)
            source_fk_vals = intermediates.filter_map { |i| i.public_send(source_assoc.foreign_key) }.uniq
            targets = source_assoc.klass.where(
              source_assoc.primary_key => { '$in' => source_fk_vals }
            ).to_a
            targets_by_pk = targets.group_by { |t| t.public_send(source_assoc.primary_key) }

            result = Hash.new { |h, k| h[k] = [] }
            intermediates.each do |i|
              owner_fk_val = i.public_send(through_fk)
              matched = targets_by_pk[i.public_send(source_assoc.foreign_key)] || []
              result[owner_fk_val].concat(matched)
            end
            result
          end

          # FK is on the source (e.g. reader.book_id -> has_many :readers on Book).
          def fk_on_source_targets_map(intermediates, through_fk, source_assoc)
            source_pk = source_assoc.primary_key
            intermediate_pks = intermediates.filter_map { |i| i.public_send(source_pk) }.uniq
            targets = source_assoc.klass.where(
              source_assoc.foreign_key => { '$in' => intermediate_pks }
            ).to_a
            targets_by_source_fk = targets.group_by { |t| t.public_send(source_assoc.foreign_key) }

            result = Hash.new { |h, k| h[k] = [] }
            intermediates.each do |i|
              owner_fk_val = i.public_send(through_fk)
              matched = targets_by_source_fk[i.public_send(source_pk)] || []
              result[owner_fk_val].concat(matched)
            end
            result
          end

          def set_relation(doc, element)
            return if doc.blank?

            proxy = HasManyThrough::Proxy.new(doc, @association, preloaded: element)
            doc.set_relation(@association.name, proxy)
          end

          # Required by base class contract. Not called from preload since this
          # class manages its own two-query traversal directly.
          def group_by_key
            @association.through_association.primary_key
          end
        end
      end
    end
  end
end
