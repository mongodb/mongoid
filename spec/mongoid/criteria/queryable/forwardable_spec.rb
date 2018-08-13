# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Queryable::Forwardable do

  describe ".select_with" do

    context "when extending from a class" do

      before(:all) do
        class Mountain
          extend Mongoid::Criteria::Queryable::Forwardable
          select_with :queryable

          def self.queryable
            Query.new
          end
        end
      end

      after(:all) do
        Object.send(:remove_const, :Mountain)
      end

      context "when provided a symbol" do

        Mongoid::Criteria::Queryable::Selectable.forwardables.each do |method|

          it "forwards #{method} to the provided method name" do
            expect(Mountain).to respond_to(method)
          end
        end

        Mongoid::Criteria::Queryable::Optional.forwardables.each do |method|

          it "forwards #{method} to the provided method name" do
            expect(Mountain).to respond_to(method)
          end
        end
      end
    end

    context "when extending from a module" do

      before(:all) do
        module Finders
          extend Mongoid::Criteria::Queryable::Forwardable
          select_with :queryable

          def self.queryable
            Query.new
          end
        end
      end

      after(:all) do
        Object.send(:remove_const, :Finders)
      end

      context "when provided a symbol" do

        before(:all) do
          class Mountain
            extend Finders
          end
        end

        after(:all) do
          Object.send(:remove_const, :Mountain)
        end

        Mongoid::Criteria::Queryable::Selectable.forwardables.each do |method|

          it "forwards #{method} to the provided method name" do
            expect(Mountain).to respond_to(method)
          end
        end

        Mongoid::Criteria::Queryable::Optional.forwardables.each do |method|

          it "forwards #{method} to the provided method name" do
            expect(Mountain).to respond_to(method)
          end
        end
      end
    end
  end
end
