# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe 'Matcher.extract_attribute' do
  Dir[File.join(File.dirname(__FILE__), 'extract_attribute_data', '*.yml')].sort.each do |path|
    context File.basename(path) do
      specs = YAML.load(File.read(path))

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

          let(:expected_exists) { spec['exists'] }
          let(:expected_value) { spec['value'] }
          let(:expected_expanded) { spec['expanded'] }

          it 'has the expected exists flag' do
            actual[0].should == expected_exists
          end

          it 'has the expected value' do
            actual[1].should == expected_value
          end

          it 'has the expected expanded flag' do
            actual[2].should == expected_expanded
          end
        end
      end
    end
  end
end
