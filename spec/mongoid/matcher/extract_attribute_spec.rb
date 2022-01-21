# frozen_string_literal: true

require 'spec_helper'

describe 'Matcher.extract_attribute' do
  Dir[File.join(File.dirname(__FILE__), 'extract_attribute_data', '*.yml')].sort.each do |path|
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

          let(:document) do
            spec['document']
          end

          let(:key) { spec['key'] }

          let(:actual) do
            Mongoid::Matcher.extract_attribute(document, key)
          end

          let(:expected) { spec.fetch('result') }

          it 'has the expected result' do
            actual.should == expected
          end
        end
      end
    end
  end
end
