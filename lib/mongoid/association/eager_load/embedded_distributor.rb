# frozen_string_literal: true

module Mongoid
  module Association
    # Objects that carry out the aggregation-based eager load triggered by
    # Criteria#eager_load.
    module EagerLoad
      # Distributes the results of a $lookup onto the embedded documents they
      # belong to.
      #
      # A $lookup overwrites the single field it writes to, and it can't distribute
      # its matches across the elements of an embedded array. So when the reference
      # being eager-loaded lives on an embedded document, the matches are first
      # collected in a temporary top-level field and then distributed down the
      # embedded path onto each embedded document, merging into it (so the rest of
      # the document is kept) and correlating by key. The temporary field is then
      # dropped.
      #
      # For Computer.eager_load(port: :device) (Port belongs_to :device) it emits:
      #
      #   { '$lookup' => {                     # devices can't be written into
      #     'from' => 'devices',               # the embedded port, so they are
      #     'localField' => 'port.device_id',  # collected in a temp top-level
      #     'foreignField' => '_id',           # field instead
      #     'as' => '__eager_load_port_device'
      #   } },
      #   { '$set' => {
      #     'port' => { '$mergeObjects' => [   # merge a 'device' key onto the port
      #       '$port',
      #       { 'device' => { '$filter' => { ... } } }   # this port's matches
      #     ] }
      #   } },
      #   { '$unset' => '__eager_load_port_device' }  # drop the temp field
      class EmbeddedDistributor
        # @param [ Mongoid::Association::Relatable ] association The referenced
        #   inclusion being eager-loaded from within an embedded document.
        # @param [ Array<Mongoid::Association::Relatable> ] chain The embedded
        #   ancestors, from the root document inward, down to the association's owner.
        # @param [ Hash ] lookup_stage The $lookup stage built for the association.
        #
        # @return [ EmbeddedDistributor ] The distributor.
        class << self
          def for(association:, chain:, lookup_stage:)
            lookup = lookup_stage['$lookup']
            new(association, chain, lookup_stage, lookup['localField'], lookup['foreignField'])
          end

          private :new
        end

        def initialize(association, chain, lookup_stage, local_field, foreign_field)
          @association = association
          @chain = chain
          @lookup_stage = lookup_stage
          @local_field = local_field
          @foreign_field = foreign_field
        end

        # The stages that run the $lookup into a temporary field and then
        # distribute its matches onto the embedded documents along the path.
        #
        # @return [ Array<Hash> ] The stages to append to the pipeline.
        def stages
          redirect_lookup_to_temporary_field
          [
            @lookup_stage,
            { '$set' => {
              root => distributed_value(@chain, "$#{root}")
            } },
            { '$unset' => temporary_field }
          ]
        end

        private

        # The $lookup runs at the top level, so it reads the local field by its
        # full embedded path and writes the matches into the temporary field.
        def redirect_lookup_to_temporary_field
          lookup = @lookup_stage['$lookup']
          lookup['localField'] = "#{path}.#{@local_field}"
          lookup['as'] = temporary_field
        end

        def path
          @chain.map(&:store_as).join('.')
        end

        def root
          @chain.first.store_as
        end

        def temporary_field
          "__eager_load_#{path.tr('.', '_')}_#{@association.name}"
        end

        # An embedded collection (embeds_many) is rebuilt with $map so each element
        # keeps its own matches instead of collapsing onto the first; a single
        # embedded document (embeds_one) receives its matches in place.
        def distributed_value(chain, node)
          head, *rest = chain
          many = head.many?
          element = many ? "$$#{head.store_as}" : node
          child =
            if rest.empty?
              { @association.name.to_s => correlated_matches(element) }
            else
              segment = rest.first.store_as
              { segment => distributed_value(rest, "#{element}.#{segment}") }
            end
          merged = { '$mergeObjects' => [ element, child ] }
          return merged unless many

          { '$map' => {
            'input' => node,
            'as' => head.store_as,
            'in' => merged
          } }
        end

        # The matches that belong to a single embedded element.
        def correlated_matches(element)
          { '$filter' => {
            'input' => "$#{temporary_field}",
            'as' => 'match',
            'cond' => { match_operator => [ "$$match.#{@foreign_field}", "#{element}.#{@local_field}" ] }
          } }
        end

        # A has_and_belongs_to_many holds an array of foreign keys, so a match
        # belongs when its key is among them ($in); every other association points
        # at a single key ($eq).
        def match_operator
          @association.many_to_many? ? '$in' : '$eq'
        end
      end
    end
  end
end
