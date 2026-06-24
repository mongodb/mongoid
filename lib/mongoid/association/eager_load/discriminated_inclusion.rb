# frozen_string_literal: true

require 'mongoid/association/eager_load/inclusion'

module Mongoid
  module Association
    module EagerLoad
      # Loads an inclusion that more than one subclass defines under the same name
      # but pointing at different targets. A single $lookup can't serve them: they
      # would all write to the same field and overwrite one another. So each
      # subclass's inclusion is contributed into its own temporary field, carrying
      # its own nested children, and a $set then routes every document to the field
      # for its own type, by the discriminator.
      #
      # For Machine.eager_load(:widgets), where Lathe#widgets => Cog and
      # Press#widgets => Belt, it emits:
      #
      #   { '$lookup' => { 'from' => 'cogs',  ..., 'as' => '__eager_load_widgets_Lathe' } },
      #   { '$lookup' => { 'from' => 'belts', ..., 'as' => '__eager_load_widgets_Press' } },
      #   { '$set' => {
      #     'widgets' => { '$switch' => { 'branches' => [   # route each document to its
      #       { 'case' => { '$eq' => [ '$_type', 'Lathe' ] }, 'then' => '$__eager_load_widgets_Lathe' },  # own type's matches
      #       { 'case' => { '$eq' => [ '$_type', 'Press' ] }, 'then' => '$__eager_load_widgets_Press' }
      #     ], 'default' => [] } }
      #   } },
      #   { '$unset' => [ '__eager_load_widgets_Lathe', '__eager_load_widgets_Press' ] }
      #
      # @api private
      class DiscriminatedInclusion < Inclusion
        def initialize(nodes)
          super()
          @nodes = nodes
        end

        # Append each subclass's lookup (into its own temporary field), the routing
        # $set, and the cleanup $unset.
        #
        # @param [ Array<Hash> ] destination The pipeline the stages are appended to.
        def contribute(destination, _chain)
          fields = @nodes.map { |node| [ node, contribute_into_temporary(destination, node) ] }
          destination << route_by_type(fields)
          destination << { '$unset' => fields.map { |_node, field| field } }
        end

        private

        # Let the node build its own $lookup (with its nested children) and redirect
        # it to write into a temporary field instead of the shared association name.
        def contribute_into_temporary(destination, node)
          field = temporary_field(node)
          captured = []
          node.contribute(captured, [])
          captured.first['$lookup']['as'] = field
          destination.concat(captured)
          field
        end

        def temporary_field(node)
          "__eager_load_#{node.association.name}_#{owner(node).discriminator_value}"
        end

        # The $set that fills the association on each document from the temporary
        # field matching its own type.
        def route_by_type(fields)
          branches = fields.map do |node, field|
            {
              'case' => { '$eq' => [ "$#{discriminator_key}", owner(node).discriminator_value ] },
              'then' => "$#{field}"
            }
          end
          { '$set' => { name => { '$switch' => { 'branches' => branches, 'default' => [] } } } }
        end

        def owner(node)
          node.association.inverse_class
        end

        def name
          @nodes.first.association.name.to_s
        end

        def discriminator_key
          owner(@nodes.first).discriminator_key
        end
      end
    end
  end
end
