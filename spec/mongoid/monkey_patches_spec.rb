# frozen_string_literal: true

require 'spec_helper'

# @note This test ensures that we do not inadvertently introduce new monkey patches
# to Mongoid. Existing monkey patch methods which are marked with +Mongoid.deprecated+
# are excluded from this test.
RSpec.describe('Do not add monkey patches') do
  classes = [
    Object,
    Array,
    BigDecimal,
    Date,
    DateTime,
    FalseClass,
    Float,
    Hash,
    Integer,
    Module,
    NilClass,
    Range,
    Regexp,
    Set,
    String,
    Symbol,
    Time,
    TrueClass,
    ActiveSupport::TimeWithZone,
    BSON::Binary,
    BSON::Decimal128,
    BSON::ObjectId,
    BSON::Regexp,
    BSON::Regexp::Raw
  ]

  expected_instance_methods = {
    Object => %i[
      __add__
      __add_from_array__
      __array__
      __deep_copy__
      __evolve_object_id__
      __expand_complex__
      __intersect__
      __intersect_from_array__
      __intersect_from_object__
      __mongoize_object_id__
      __union__
      __union_from_object__
      ivar
      mongoize
      numeric?
      remove_ivar
      resizable?
      substitutable
    ],
    Array => %i[
      __evolve_date__
      __evolve_time__
      __mongoize_time__
      __sort_option__
      __sort_pair__
      delete_one
    ],
    Date => %i[
      __evolve_date__
      __evolve_time__
      __mongoize_time__
    ],
    DateTime => %i[
      __evolve_date__
      __evolve_time__
      __mongoize_time__
    ],
    FalseClass => %i[is_a?],
    Float => %i[
      __evolve_date__
      __evolve_time__
      __mongoize_time__
    ],
    Hash => %i[
      __sort_option__
    ],
    Integer => %i[
      __evolve_date__
      __evolve_time__
      __mongoize_time__
    ],
    Module => %i[
      re_define_method
    ],
    NilClass => %i[
      __evolve_date__
      __evolve_time__
      __expanded__
      __override__
      collectionize
    ],
    Range => %i[
      __evolve_date__
      __evolve_range__
      __evolve_time__
    ],
    String => %i[
      __evolve_date__
      __evolve_time__
      __expr_part__
      __mongo_expression__
      __mongoize_time__
      __sort_option__
      before_type_cast?
      collectionize
      reader
      valid_method_name?
      writer?
    ],
    Symbol => %i[
      __expr_part__
      add_to_set
      all
      asc
      ascending
      avg
      desc
      descending
      elem_match
      eq
      exists
      first
      gt
      gte
      in
      intersects_line
      intersects_point
      intersects_polygon
      last
      lt
      lte
      max
      min
      mod
      ne
      near
      near_sphere
      nin
      not
      push
      sum
      with_size
      with_type
      within_box
      within_polygon
    ],
    TrueClass => %i[is_a?],
    Time => %i[
      __evolve_date__
      __evolve_time__
      __mongoize_time__
    ],
    ActiveSupport::TimeWithZone => %i[
      __evolve_date__
      __evolve_time__
      __mongoize_time__
      _bson_to_i
    ],
    BSON::Decimal128 => %i[
      __evolve_decimal128__
    ]
  }.each_value(&:sort!)

  expected_class_methods = {
    Object => %i[
      demongoize
      evolve
      re_define_method
    ],
    Float => %i[__numeric__],
    Integer => %i[__numeric__],
    String => %i[__expr_part__],
    Symbol => %i[add_key]
  }.each_value(&:sort!)

  def mongoid_method?(method)
    method.source_location&.first&.include?('/lib/mongoid/')
  end

  def added_instance_methods(klass)
    methods = klass.instance_methods.select { |m| mongoid_method?(klass.instance_method(m)) }
    methods -= added_instance_methods(Object) unless klass == Object
    methods.sort
  end

  def added_class_methods(klass)
    methods = klass.methods.select { |m| mongoid_method?(klass.method(m)) }
    methods -= added_instance_methods(Object)
    methods -= added_class_methods(Object) unless klass == Object
    methods.sort
  end

  classes.each do |klass|
    context klass.name do
      it 'adds no unexpected instance methods' do
        expect(added_instance_methods(klass)).to eq(expected_instance_methods[klass] || [])
      end

      it 'adds no unexpected class methods' do
        expect(added_class_methods(klass)).to eq(expected_class_methods[klass] || [])
      end
    end
  end
end
