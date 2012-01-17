require "spec_helper"

describe Mongoid::Criterion::Scoping do

  describe "#apply_default_scope" do

    context "when a default scope exists" do

      let(:criteria) do
        Mongoid::Criteria.new(Acolyte).where(:name => "first")
      end

      context "when the default scope has not been applied" do

        let(:applied) do
          criteria.apply_default_scope
        end

        it "fuses the default scope" do
          applied.options.should eq({ :sort => [[ :name, :asc ]]})
        end

        it "contains the same original criterion" do
          applied.selector.should eq(criteria.selector)
        end

        it "returns a cloned criteria" do
          applied.should_not equal(criteria)
        end

        it "flags the default scope as being applied" do
          applied.should_not be_default_scopable
        end
      end

      context "when the default scope has been applied" do

        let(:applied) do
          criteria.apply_default_scope
        end

        it "returns the existing criteria" do
          applied.apply_default_scope.should equal(applied)
        end
      end

      context "when the criteria is unscoped" do

        let(:unscoped) do
          criteria.unscoped
        end

        let(:applied) do
          unscoped.apply_default_scope
        end

        it "returns the existing criteria" do
          applied.should equal(unscoped)
        end

        it "does not apply the default scoping" do
          applied.options.should be_empty
        end
      end
    end
  end

  describe "#scoped" do

    context "when a default scope exists" do

      let(:criteria) do
        Mongoid::Criteria.new(Acolyte).where(:name => "first")
      end

      context "when the default scope has not been applied" do

        let(:applied) do
          criteria.scoped
        end

        it "fuses the default scope" do
          applied.options.should eq({ :sort => [[ :name, :asc ]]})
        end

        it "contains the same original criterion" do
          applied.selector.should eq(criteria.selector)
        end

        it "returns a cloned criteria" do
          applied.should_not equal(criteria)
        end

        it "flags the default scope as being applied" do
          applied.should_not be_default_scopable
        end
      end

      context "when the default scope has been applied" do

        let(:applied) do
          criteria.scoped
        end

        it "returns a cloned criteria" do
          applied.scoped.should eq(applied)
        end
      end

      context "when the criteria is unscoped" do

        let(:unscoped) do
          criteria.unscoped
        end

        let(:applied) do
          unscoped.scoped
        end

        it "fuses the default scope" do
          applied.options.should eq({ :sort => [[ :name, :asc ]]})
        end

        it "clears the criteria scoping" do
          applied.selector.should be_empty
        end

        it "returns a cloned criteria" do
          applied.should_not equal(criteria)
        end

        it "flags the default scope as being applied" do
          applied.should_not be_default_scopable
        end
      end
    end
  end

  describe "#unscoped" do

    context "when a default scope exists" do

      let(:criteria) do
        Mongoid::Criteria.new(Acolyte).where(:name => "first")
      end

      context "when the default scope has been applied" do

        let(:applied) do
          criteria.apply_default_scope
        end

        let(:unscoped) do
          applied.unscoped
        end

        it "returns a new criteria" do
          unscoped.should_not equal(applied)
        end

        it "removes the scoping" do
          unscoped.selector.should be_empty
        end

        it "removes the default scope options" do
          unscoped.options.should be_empty
        end

        it "flags the criteria as unscopable" do
          unscoped.should_not be_default_scopable
        end
      end
    end
  end
end
