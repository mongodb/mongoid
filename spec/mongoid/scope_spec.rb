require "spec_helper"

describe Mongoid::Scope do

  describe ".initialize" do

    let(:conditions) do
      {:field => "value"}
    end

    let(:scope) do
      Mongoid::Scope.new(conditions)
    end

    it "stores the provided conditions" do
      scope.conditions.should eq(conditions)
    end

    context "when a block is passed in" do

      let(:scope) do
        Mongoid::Scope.new({}) do
          def extended
            "extended"
          end
        end
      end

      it "it stores the extensions" do
        scope.extensions.should be_a(Module)
      end
    end
  end
end
