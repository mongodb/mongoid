# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Contextual::Aggregable::Memory do

  let(:criteria) do
    Band.all.tap do |crit|
      crit.documents = documents
    end
  end

  let(:context) do
    Mongoid::Contextual::Memory.new(criteria)
  end

  file = File.read(File.join(File.dirname(__FILE__), 'memory_table.yml'))
  table = if RUBY_VERSION.start_with?("2.5")
            YAML.safe_load(file, [BigDecimal])
          else
            YAML.safe_load(file, permitted_classes: [BigDecimal])
          end.deep_symbolize_keys.fetch(:sets)

  table.each do |name, spec|
    context "DB values are #{name}" do
      let(:documents) do
        spec[:values].map do |value|
          Band.create!({ name: 'Foobar', views: value, rating: value, sales: value, mojo: value })
        end
      end

      { integer: :views,
        float: :rating,
        big_decimal: :sales }.each do |type, field|

        %i[sum avg min max].each do |method|
          context "#{type.to_s.camelize} field :#{method}" do
            let(:expected) do
              spec.dig(:expected, type, method)
            end

            let(:result) do
              context.send(method, field)
            end

            it 'produces the expected result' do
              if result.is_a?(Integer)
                expect(result).to eq expected
              else
                expect(result).to be_within(0.001).of(expected)
              end
            end

            it 'produces the expected type' do
              expect(result).to be_a expected.class
            end
          end
        end
      end
    end
  end
end
