require "spec_helper"

describe Origin::Forwardable do

  describe ".select_with" do

    context "when extending from a class" do

      before(:all) do
        class Band
          extend Origin::Forwardable
          select_with :queryable

          def self.queryable
            Query.new
          end
        end
      end

      after(:all) do
        Object.send(:remove_const, :Band)
      end

      context "when provided a symbol" do

        Origin::Selectable.forwardables.each do |method|

          it "forwards #{method} to the provided method name" do
            expect(Band).to respond_to(method)
          end
        end

        Origin::Optional.forwardables.each do |method|

          it "forwards #{method} to the provided method name" do
            expect(Band).to respond_to(method)
          end
        end
      end
    end

    context "when extending from a module" do

      before(:all) do
        module Finders
          extend Origin::Forwardable
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
          class Band
            extend Finders
          end
        end

        after(:all) do
          Object.send(:remove_const, :Band)
        end

        Origin::Selectable.forwardables.each do |method|

          it "forwards #{method} to the provided method name" do
            expect(Band).to respond_to(method)
          end
        end

        Origin::Optional.forwardables.each do |method|

          it "forwards #{method} to the provided method name" do
            expect(Band).to respond_to(method)
          end
        end
      end
    end
  end
end
