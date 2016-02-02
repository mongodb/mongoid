# encoding: utf-8
module Origin

  # An origin selectable is selectable, in that it has the ability to select
  # document from the database. The selectable module brings all functionality
  # to the selectable that has to do with building MongoDB selectors.
  module Selectable
    extend Macroable

    # Constant for a LineString $geometry.
    #
    # @since 2.0.0
    LINE_STRING = "LineString"

    # Constant for a Point $geometry.
    #
    # @since 2.0.0
    POINT = "Point"

    # Constant for a Polygon $geometry.
    #
    # @since 2.0.0
    POLYGON = "Polygon"

    # @attribute [rw] negating If the next spression is negated.
    # @attribute [rw] selector The query selector.
    attr_accessor :negating, :selector

    # Add the $all criterion.
    #
    # @example Add the criterion.
    #   selectable.all(field: [ 1, 2 ])
    #
    # @example Execute an $all in a where query.
    #   selectable.where(:field.all => [ 1, 2 ])
    #
    # @param [ Hash ] criterion The key value pairs for $all matching.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def all(criterion = nil)
      send(strategy || :__union__, with_array_values(criterion), "$all")
    end
    alias :all_in :all
    key :all, :union, "$all"

    # Add the $and criterion.
    #
    # @example Add the criterion.
    #   selectable.and({ field: value }, { other: value })
    #
    # @param [ Array<Hash> ] criterion Multiple key/value pair matches that
    #   all must match to return results.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def and(*criterion)
      __multi__(criterion, "$and")
    end
    alias :all_of :and

    # Add the range selection.
    #
    # @example Match on results within a single range.
    #   selectable.between(field: 1..2)
    #
    # @example Match on results between multiple ranges.
    #   selectable.between(field: 1..2, other: 5..7)
    #
    # @param [ Hash ] criterion Multiple key/range pairs.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def between(criterion = nil)
      selection(criterion) do |selector, field, value|
        selector.store(
          field,
          { "$gte" => value.min, "$lte" => value.max }
        )
      end
    end

    # Select with an $elemMatch.
    #
    # @example Add criterion for a single match.
    #   selectable.elem_match(field: { name: "value" })
    #
    # @example Add criterion for multiple matches.
    #   selectable.elem_match(
    #     field: { name: "value" },
    #     other: { name: "value"}
    #   )
    #
    # @example Execute an $elemMatch in a where query.
    #   selectable.where(:field.elem_match => { name: "value" })
    #
    # @param [ Hash ] criterion The field/match pairs.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def elem_match(criterion = nil)
      __override__(criterion, "$elemMatch")
    end
    key :elem_match, :override, "$elemMatch"

    # Add the $exists selection.
    #
    # @example Add a single selection.
    #   selectable.exists(field: true)
    #
    # @example Add multiple selections.
    #   selectable.exists(field: true, other: false)
    #
    # @example Execute an $exists in a where query.
    #   selectable.where(:field.exists => true)
    #
    # @param [ Hash ] criterion The field/boolean existence checks.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def exists(criterion = nil)
      typed_override(criterion, "$exists") do |value|
        ::Boolean.evolve(value)
      end
    end
    key :exists, :override, "$exists" do |value|
      ::Boolean.evolve(value)
    end

    # Add a $geoIntersects or $geoWithin selection. Symbol operators must be used as shown in
    # the examples to expand the criteria.
    #
    # @note The only valid geometry shapes for a $geoIntersects are:
    #   :intersects_line, :intersects_point, and :intersects_polygon.
    #
    # @note The only valid geometry shape for a $geoWithin is :within_polygon
    #
    # @example Add a geo intersect criterion for a line.
    #   query.geo_spacial(:location.intersects_line => [[ 1, 10 ], [ 2, 10 ]])
    #
    # @example Add a geo intersect criterion for a point.
    #   query.geo_spacial(:location.intersects_point => [[ 1, 10 ]])
    #
    # @example Add a geo intersect criterion for a polygon.
    #   query.geo_spacial(:location.intersects_polygon => [[ 1, 10 ], [ 2, 10 ], [ 1, 10 ]])
    #
    # @example Add a geo within criterion for a polygon.
    #   query.geo_spacial(:location.within_polygon => [[ 1, 10 ], [ 2, 10 ], [ 1, 10 ]])
    #
    # @param [ Hash ] criterion The criterion.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 2.0.0
    def geo_spacial(criterion = nil)
      __merge__(criterion)
    end
    key :intersects_line, :override, "$geoIntersects", "$geometry" do |value|
      { "type" => LINE_STRING, "coordinates" => value }
    end
    key :intersects_point, :override, "$geoIntersects", "$geometry" do |value|
      { "type" => POINT, "coordinates" => value }
    end
    key :intersects_polygon, :override, "$geoIntersects", "$geometry" do |value|
      { "type" => POLYGON, "coordinates" => value }
    end
    key :within_polygon, :override, "$geoWithin", "$geometry" do |value|
      { "type" => POLYGON, "coordinates" => value }
    end

    # Add the $gt criterion to the selector.
    #
    # @example Add the $gt criterion.
    #   selectable.gt(age: 60)
    #
    # @example Execute an $gt in a where query.
    #   selectable.where(:field.gt => 10)
    #
    # @param [ Hash ] criterion The field/value pairs to check.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def gt(criterion = nil)
      __override__(criterion, "$gt")
    end
    key :gt, :override, "$gt"

    # Add the $gte criterion to the selector.
    #
    # @example Add the $gte criterion.
    #   selectable.gte(age: 60)
    #
    # @example Execute an $gte in a where query.
    #   selectable.where(:field.gte => 10)
    #
    # @param [ Hash ] criterion The field/value pairs to check.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def gte(criterion = nil)
      __override__(criterion, "$gte")
    end
    key :gte, :override, "$gte"

    # Adds the $in selection to the selectable.
    #
    # @example Add $in selection on an array.
    #   selectable.in(age: [ 1, 2, 3 ])
    #
    # @example Add $in selection on a range.
    #   selectable.in(age: 18..24)
    #
    # @example Execute an $in in a where query.
    #   selectable.where(:field.in => [ 1, 2, 3 ])
    #
    # @param [ Hash ] criterion The field/value criterion pairs.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def in(criterion = nil)
      send(strategy || :__intersect__, with_array_values(criterion), "$in")
    end
    alias :any_in :in
    key :in, :intersect, "$in"

    # Add the $lt criterion to the selector.
    #
    # @example Add the $lt criterion.
    #   selectable.lt(age: 60)
    #
    # @example Execute an $lt in a where query.
    #   selectable.where(:field.lt => 10)
    #
    # @param [ Hash ] criterion The field/value pairs to check.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def lt(criterion = nil)
      __override__(criterion, "$lt")
    end
    key :lt, :override, "$lt"

    # Add the $lte criterion to the selector.
    #
    # @example Add the $lte criterion.
    #   selectable.lte(age: 60)
    #
    # @example Execute an $lte in a where query.
    #   selectable.where(:field.lte => 10)
    #
    # @param [ Hash ] criterion The field/value pairs to check.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def lte(criterion = nil)
      __override__(criterion, "$lte")
    end
    key :lte, :override, "$lte"

    # Add a $maxDistance selection to the selectable.
    #
    # @example Add the $maxDistance selection.
    #   selectable.max_distance(location: 10)
    #
    # @param [ Hash ] criterion The field/distance pairs.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def max_distance(criterion = nil)
      __add__(criterion, "$maxDistance")
    end

    # Adds $mod selection to the selectable.
    #
    # @example Add the $mod selection.
    #   selectable.mod(field: [ 10, 1 ])
    #
    # @example Execute an $mod in a where query.
    #   selectable.where(:field.mod => [ 10, 1 ])
    #
    # @param [ Hash ] criterion The field/mod selections.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def mod(criterion = nil)
      __override__(criterion, "$mod")
    end
    key :mod, :override, "$mod"

    # Adds $ne selection to the selectable.
    #
    # @example Query for a value $ne to something.
    #   selectable.ne(field: 10)
    #
    # @example Execute an $ne in a where query.
    #   selectable.where(:field.ne => "value")
    #
    # @param [ Hash ] criterion The field/ne selections.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def ne(criterion = nil)
      __override__(criterion, "$ne")
    end
    alias :excludes :ne
    key :ne, :override, "$ne"

    # Adds a $near criterion to a geo selection.
    #
    # @example Add the $near selection.
    #   selectable.near(location: [ 23.1, 12.1 ])
    #
    # @example Execute an $near in a where query.
    #   selectable.where(:field.near => [ 23.2, 12.1 ])
    #
    # @param [ Hash ] criterion The field/location pair.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def near(criterion = nil)
      __override__(criterion, "$near")
    end
    key :near, :override, "$near"

    # Adds a $nearSphere criterion to a geo selection.
    #
    # @example Add the $nearSphere selection.
    #   selectable.near_sphere(location: [ 23.1, 12.1 ])
    #
    # @example Execute an $nearSphere in a where query.
    #   selectable.where(:field.near_sphere => [ 10.11, 3.22 ])
    #
    # @param [ Hash ] criterion The field/location pair.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def near_sphere(criterion = nil)
      __override__(criterion, "$nearSphere")
    end
    key :near_sphere, :override, "$nearSphere"

    # Adds the $nin selection to the selectable.
    #
    # @example Add $nin selection on an array.
    #   selectable.nin(age: [ 1, 2, 3 ])
    #
    # @example Add $nin selection on a range.
    #   selectable.nin(age: 18..24)
    #
    # @example Execute an $nin in a where query.
    #   selectable.where(:field.nin => [ 1, 2, 3 ])
    #
    # @param [ Hash ] criterion The field/value criterion pairs.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def nin(criterion = nil)
      send(strategy || :__intersect__, with_array_values(criterion), "$nin")
    end
    alias :not_in :nin
    key :nin, :intersect, "$nin"

    # Adds $nor selection to the selectable.
    #
    # @example Add the $nor selection.
    #   selectable.nor(field: 1, field: 2)
    #
    # @param [ Array ] criterion An array of hash criterion.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def nor(*criterion)
      __multi__(criterion, "$nor")
    end

    # Is the current selectable negating the next selection?
    #
    # @example Is the selectable negating?
    #   selectable.negating?
    #
    # @return [ true, false ] If the selectable is negating.
    #
    # @since 1.0.0
    def negating?
      !!negating
    end

    # Negate the next selection.
    #
    # @example Negate the selection.
    #   selectable.not.in(field: [ 1, 2 ])
    #
    # @example Add the $not criterion.
    #   selectable.not(name: /Bob/)
    #
    # @example Execute a $not in a where query.
    #   selectable.where(:field.not => /Bob/)
    #
    # @param [ Hash ] criterion The field/value pairs to negate.
    #
    # @return [ Selectable ] The negated selectable.
    #
    # @since 1.0.0
    def not(*criterion)
      if criterion.empty?
        tap { |query| query.negating = true }
      else
        __override__(criterion.first, "$not")
      end
    end
    key :not, :override, "$not"

    # Adds $or selection to the selectable.
    #
    # @example Add the $or selection.
    #   selectable.or(field: 1, field: 2)
    #
    # @param [ Array ] criterion An array of hash criterion.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def or(*criterion)
      __multi__(criterion, "$or")
    end
    alias :any_of :or

    # Add a $size selection for array fields.
    #
    # @example Add the $size selection.
    #   selectable.with_size(field: 5)
    #
    # @note This method is named #with_size not to conflict with any existing
    #   #size method on enumerables or symbols.
    #
    # @example Execute an $size in a where query.
    #   selectable.where(:field.with_size => 10)
    #
    # @param [ Hash ] criterion The field/size pairs criterion.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def with_size(criterion = nil)
      typed_override(criterion, "$size") do |value|
        ::Integer.evolve(value)
      end
    end
    key :with_size, :override, "$size" do |value|
      ::Integer.evolve(value)
    end

    # Adds a $type selection to the selectable.
    #
    # @example Add the $type selection.
    #   selectable.with_type(field: 15)
    #
    # @example Execute an $type in a where query.
    #   selectable.where(:field.with_type => 15)
    #
    # @note http://vurl.me/PGOU contains a list of all types.
    #
    # @param [ Hash ] criterion The field/type pairs.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def with_type(criterion = nil)
      typed_override(criterion, "$type") do |value|
        ::Integer.evolve(value)
      end
    end
    key :with_type, :override, "$type" do |value|
      ::Integer.evolve(value)
    end

    # Construct a text search selector.
    #
    # @example Construct a text search selector.
    #   selectable.text_search("testing")
    #
    # @example Construct a text search selector with options.
    #   selectable.text_search("testing", :$language => "fr")
    #
    # @param [ String, Symbol ] terms A string of terms that MongoDB parses
    #   and uses to query the text index.
    # @param [ Hash ] opts Text search options. See MongoDB documentation
    #   for options.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 2.2.0
    def text_search(terms, opts = nil)
      clone.tap do |query|
        if terms
          criterion = { :$text => { :$search => terms } }
          criterion[:$text].merge!(opts) if opts
          query.selector = criterion
        end
      end
    end

    # This is the general entry point for most MongoDB queries. This either
    # creates a standard field: value selection, and expanded selection with
    # the use of hash methods, or a $where selection if a string is provided.
    #
    # @example Add a standard selection.
    #   selectable.where(name: "syd")
    #
    # @example Add a javascript selection.
    #   selectable.where("this.name == 'syd'")
    #
    # @param [ String, Hash ] criterion The javascript or standard selection.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def where(criterion = nil)
      criterion.is_a?(String) ? js_query(criterion) : expr_query(criterion)
    end

    private

    # Create the standard expression query.
    #
    # @api private
    #
    # @example Create the selection.
    #   selectable.expr_query(age: 50)
    #
    # @param [ Hash ] criterion The field/value pairs.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def expr_query(criterion)
      selection(criterion) do |selector, field, value|
        selector.merge!(field.__expr_part__(value.__expand_complex__, negating?))
      end
    end

    # Force the values of the criterion to be evolved.
    #
    # @api private
    #
    # @example Force values to booleans.
    #   selectable.force_typing(criterion) do |val|
    #     Boolean.evolve(val)
    #   end
    #
    # @param [ Hash ] criterion The criterion.
    #
    # @since 1.0.0
    def typed_override(criterion, operator)
      if criterion
        criterion.update_values do |value|
          yield(value)
        end
      end
      __override__(criterion, operator)
    end

    # Create a javascript selection.
    #
    # @api private
    #
    # @example Create the javascript selection.
    #   selectable.js_query("this.age == 50")
    #
    # @param [ String ] criterion The javascript as a string.
    #
    # @return [ Selectable ] The cloned selectable
    #
    # @since 1.0.0
    def js_query(criterion)
      clone.tap do |query|
        query.selector.merge!("$where" => criterion)
      end
    end

    # Take the provided criterion and store it as a selection in the query
    # selector.
    #
    # @api private
    #
    # @example Store the selection.
    #   selectable.selection({ field: "value" })
    #
    # @param [ Hash ] criterion The selection to store.
    #
    # @return [ Selectable ] The cloned selectable.
    #
    # @since 1.0.0
    def selection(criterion = nil)
      clone.tap do |query|
        if criterion
          criterion.each_pair do |field, value|
            yield(query.selector, field.is_a?(Key) ? field : field.to_s, value)
          end
        end
        query.reset_strategies!
      end
    end

    # Convert the criterion values to $in friendly values. This means you,
    # array.
    #
    # @api private
    #
    # @example Convert all the values to arrays.
    #   selectable.with_array_values({ key: 1...4 })
    #
    # @param [ Hash ] criterion The criterion.
    #
    # @return [ Hash ] The $in friendly criterion (array values).
    #
    # @since 1.0.0
    def with_array_values(criterion)
      return nil unless criterion
      criterion.each_pair do |key, value|
        criterion[key] = value.__array__
      end
    end

    class << self

      # Get the methods on the selectable that can be forwarded to from a model.
      #
      # @example Get the forwardable methods.
      #   Selectable.forwardables
      #
      # @return [ Array<Symbol> ] The names of the forwardable methods.
      #
      # @since 1.0.0
      def forwardables
        public_instance_methods(false) -
          [ :negating, :negating=, :negating?, :selector, :selector= ]
      end
    end
  end
end
