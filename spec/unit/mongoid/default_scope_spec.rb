require "spec_helper"

describe Mongoid::DefaultScope do

  describe ".default_scope" do

    let(:criteria) do
      Acolyte.all
    end

    it "applies the scope to any criteria" do
      criteria.options.should eq({ :sort => [[ :name, :asc ]] })
    end

    context "when combining with a named scope" do

      let(:scoped) do
        Acolyte.active
      end

      it "applies the default scope" do
        scoped.options.should eq({ :sort => [[ :name, :asc ]] })
      end
    end

    context "when calling unscoped" do

      let(:unscoped) do
        Acolyte.unscoped
      end

      it "does not contain the default scoping" do
        unscoped.options.should eq({})
      end

      context "when applying a named scope after" do

        let(:named) do
          Acolyte.unscoped.active
        end

        it "does not contain the default scoping" do
          named.options.should eq({})
        end

        context "when applying multiple scopes after" do

          let(:multiple) do
            named.named
          end

          it "does not contain the default scoping" do
            multiple.options.should eq({})
          end
        end
      end
    end
  end
end
