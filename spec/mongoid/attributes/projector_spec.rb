# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Attributes::Projector do
  Dir[File.join(File.dirname(__FILE__), 'projector_data', '*.yml')].sort.each do |path|
    context File.basename(path) do
      specs = if RUBY_VERSION.start_with?("2.5")
                YAML.safe_load(File.read(path), [], [], true)
              else
                YAML.safe_load(File.read(path), aliases: true)
              end

      specs.each do |spec|
        context spec['name'] do

          if spec['pending']
            pending spec['pending'].to_s
          end

          let(:projection) do
            spec['projection']
          end

          let(:projector) do
            Mongoid::Attributes::Projector.new(projection)
          end

          spec.fetch('queries').each do |query_spec|
            context query_spec.fetch('query').inspect do
              let(:query) { query_spec['query'] }

              context 'attribute_or_path_allowed?' do
                it "is #{query_spec.fetch('allowed')}" do
                  projector.attribute_or_path_allowed?(query).should be query_spec['allowed']
                end
              end
            end
          end
        end
      end
    end
  end
end
