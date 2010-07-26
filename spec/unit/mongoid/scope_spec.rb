require "spec_helper"

describe Mongoid::Scope do

  before do
    Person.delete_all
  end

  describe ".initialize" do

    let(:conditions) { {:field => "value"} }
    let(:scope) { Mongoid::Scope.new(conditions) }

    it "stores the provided conditions" do
      scope.conditions.should == conditions
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

  describe "#extend" do

    let(:criteria) { stub }

    context "without any extensions" do
      let(:scope) { Mongoid::Scope.new }

      it "does nothing" do
        criteria.expects(:extend).never
        scope.extend(criteria)
      end
    end

    context "with extensions" do
      let(:scope) do
        Mongoid::Scope.new() {}
      end

      it "extends the criteria" do
        criteria.expects(:extend).with(scope.extensions)
        scope.extend(criteria)
      end
    end
  end

end
