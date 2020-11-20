# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

def mop_error?(spec, kind)
  unless %w(matcher driver dsl).include?(kind)
    raise ArgumentError, "Bogus kind: #{kind}"
  end

  spec['error'] == true || spec['error'] == kind ||
    spec['error'].is_a?(Array) && spec['error'].include?(kind)
end

describe 'Matcher operators' do
  Dir[File.join(File.dirname(__FILE__), 'matcher_operator_data', '*.yml')].sort.each do |path|
    context File.basename(path) do
      specs = YAML.load(File.read(path))

      specs.each do |spec|
        context spec['name'] do

          if spec['pending']
            before do
              # Cannot use `pending` here because some of the queries may work
              # as specified (e.g. when Mongoid and server behavior differ).
              skip spec['pending'].to_s
            end
          end

          if spec['min_server_version']
            min_server_version spec['min_server_version'].to_s
          end

          let(:query) { spec.fetch('query') }
          let(:result) { spec.fetch('matches') }

          context 'embedded matching' do
            let(:document) { Mop.new(spec.fetch('document')) }

            if mop_error?(spec, 'matcher')
              it 'produces an error' do
                lambda do
                  document._matches?(query)
                end.should raise_error(Mongoid::Errors::InvalidQuery)
              end
            else
              it 'produces the correct result' do
                document._matches?(query).should be result
              end
            end
          end

          context 'server query' do
            let!(:document) { Mop.create(spec.fetch('document')) }

            context 'via driver' do
              if mop_error?(spec, 'driver')
                it 'produces an error' do
                  begin
                    Mop.collection.find(query).any?
                  rescue Mongo::Error::OperationFailure
                  rescue Mongo::Error::InvalidDocument
                  rescue BSON::Error::UnserializableClass
                  else
                    fail "Expected an exception to be raised"
                  end
                end
              else
                it 'produces the correct result' do
                  Mop.collection.find(query).any?.should be result
                end
              end
            end

            context 'via Mongoid DSL' do
              if mop_error?(spec, 'dsl')
                it 'produces an error' do
                  begin
                    Mop.where(query).any?
                  rescue Mongo::Error::OperationFailure
                  rescue BSON::Error::UnserializableClass
                  rescue Mongoid::Errors::InvalidQuery
                  rescue Mongoid::Errors::CriteriaArgumentRequired
                  else
                    fail "Expected the query to raise an error"
                  end
                end
              else
                it 'produces the correct result' do
                  Mop.where(query).any?.should be result
                end
              end
            end
          end
        end
      end
    end
  end
end
