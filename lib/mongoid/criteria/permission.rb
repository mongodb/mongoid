# frozen_string_literal: true

module Mongoid
  class Criteria
    module Permission

      [:all,
       :all_in,
       :and,
       :all_of,
       :between,
       :elem_match,
       :exists,
       :gt,
       :gte,
       :in,
       :any_in,
       :lt,
       :lte,
       :max_distance,
       :mod,
       :ne,
       :excludes,
       :near,
       :near_sphere,
       :nin,
       :not_in,
       :nor,
       :negating?,
       :not,
       :or,
       :any_of,
       :with_size,
       :with_type,
       :where,
       :within_box,
       :within_circle,
       :within_polygon,
       :within_spherical_circle
      ].each do |method|
        define_method(method) do |*criteria|
          raise Errors::CriteriaNotPermitted.new(klass, method, criteria) unless should_permit?(criteria)
          super(*criteria)
        end
      end

      private

      # Ensure that the criteria are permitted.
      #
      # @example Ignoring ActionController::Parameters
      #   should_permit?({_id: ActionController::Parameters.new("$size" => 1)})
      #
      # @api private
      #
      # @param [ Object ] criteria
      # @return [ true | false ] if should permit
      def should_permit?(criteria)
        if criteria.respond_to?(:permitted?)
          return criteria.permitted?
        elsif criteria.respond_to?(:each)
          criteria.each do |criterion|
            return false unless should_permit?(criterion)
          end
        end

        true
      end
    end
  end
end
