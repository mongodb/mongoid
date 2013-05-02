require "spec_helper"

describe Mongoid::Criterion::Scoping do

  describe "#apply_default_scope" do

    context "when the default scope has options" do

      let(:scope) do
        Band.skip(20)
      end

      before do
        Band.default_scope scope
      end

      after do
        Band.default_scoping = nil
      end

      let(:scoped) do
        Band.all.tap do |criteria|
          criteria.apply_default_scope
        end
      end

      it "merges in the options" do
        scoped.options.should eq({ skip: 20 })
      end

      it "sets scoped to true" do
        scoped.should be_scoped
      end
    end

    context "when the default scope has selection" do

      let(:scope) do
        Band.where(name: "Depeche Mode")
      end

      before do
        Band.default_scope scope
      end

      after do
        Band.default_scoping = nil
      end

      let(:scoped) do
        Band.all.tap do |criteria|
          criteria.apply_default_scope
        end
      end

      it "merges in the options" do
        scoped.selector.should eq({ "name" => "Depeche Mode" })
      end

      it "sets scoped to true" do
        scoped.should be_scoped
      end
    end

    context "when the default scope has inclusions" do

      let(:scope) do
        Band.includes(:records)
      end

      before do
        Band.default_scope scope
      end

      after do
        Band.default_scoping = nil
      end

      context "when merging with an empty criteria" do

        let(:scoped) do
          Band.all.tap do |criteria|
            criteria.apply_default_scope
          end
        end

        it "merges in the inclusions" do
          scoped.inclusions.should eq(
            [ Band.relations["records"] ]
          )
        end

        it "sets scoped to true" do
          scoped.should be_scoped
        end
      end

      context "when merging with a criteria that has inclusions" do

        let(:scoped) do
          Band.includes(:label).tap do |criteria|
            criteria.apply_default_scope
          end
        end

        it "merges in the inclusions" do
          scoped.inclusions.should eq(
            [ Band.relations["records"], Band.relations["label"] ]
          )
        end

        it "sets scoped to true" do
          scoped.should be_scoped
        end
      end
    end
  end

  describe "#remove_scoping" do

    context "when the other has selection" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      before do
        criteria.remove_scoping(criteria)
      end

      it "removes the selection" do
        criteria.selector.should be_empty
      end
    end

    context "when the other has options" do

      context "when both are options only" do

        let(:criteria) do
          Band.skip(10)
        end

        before do
          criteria.remove_scoping(criteria)
        end

        it "removes the options" do
          criteria.options.should be_empty
        end
      end

      context "when the criteria is selection only with nil" do

        let(:criteria) do
          Band.where(name: nil)
        end

        before do
          criteria.remove_scoping(Band.asc(:_id))
        end

        it "removes the options" do
          criteria.options.should be_empty
        end

        it "does not remove the selector" do
          criteria.selector.should eq({ "name" => nil })
        end
      end
    end

    context "when the other has inclusions" do

      let(:criteria) do
        Band.includes(:records, :label)
      end

      let(:other) do
        Band.includes(:label)
      end

      before do
        criteria.remove_scoping(other)
      end

      it "removes the matching inclusions" do
        criteria.inclusions.should eq([ Band.relations["records"] ])
      end
    end
  end

  describe "#scoped" do

    let(:empty) do
      Mongoid::Criteria.new(Band)
    end

    context "when no options are provided" do

      let(:scoped) do
        empty.scoped
      end

      it "returns a criteria" do
        scoped.should be_a(Mongoid::Criteria)
      end

      it "contains an empty selector" do
        scoped.selector.should be_empty
      end

      it "contains empty options" do
        scoped.options.should be_empty
      end
    end

    context "when options are provided" do

      let(:scoped) do
        empty.scoped(skip: 10, limit: 10)
      end

      it "returns a criteria" do
        scoped.should be_a(Mongoid::Criteria)
      end

      it "contains an empty selector" do
        scoped.selector.should be_empty
      end

      it "contains the options" do
        scoped.options.should eq({ skip: 10, limit: 10 })
      end
    end

    context "when a default scope exists" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      before do
        Band.default_scope criteria
      end

      after do
        Band.default_scoping = nil
      end

      let(:scoped) do
        empty.scoped
      end

      it "allows the default scope to be added" do
        scoped.selector.should eq({ "name" => "Depeche Mode" })
      end

      it "flags as scoped" do
        scoped.should be_scoped
      end

      context "when chained after an unscoped criteria" do

        let(:scoped) do
          empty.unscoped.scoped
        end

        it "reapplies the default scope" do
          scoped.selector.should eq({ "name" => "Depeche Mode" })
        end
      end
    end
  end

  describe "#scoping_options" do

    let(:criteria) do
      Band.all
    end

    before do
      criteria.scoping_options = true, false
    end

    it "returns the scoping options" do
      criteria.scoping_options.should eq([ true, false ])
    end
  end

  describe "#scoping_options=" do

    let(:criteria) do
      Band.all
    end

    before do
      criteria.scoping_options = true, true
    end

    it "sets the scoped flag" do
      criteria.should be_scoped
    end

    it "sets the unscoped flag" do
      criteria.should be_unscoped
    end
  end

  describe ".unscoped" do

    let(:empty) do
      Mongoid::Criteria.new(Band)
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    before do
      Band.default_scope criteria
    end

    after do
      Band.default_scoping = nil
    end

    context "when called directly" do

      let(:unscoped) do
        empty.unscoped
      end

      it "removes the default scope from the criteria" do
        unscoped.selector.should be_empty
      end

      context "when chained after a scoped criteria" do

        let(:unscoped) do
          empty.scoped.unscoped
        end

        it "removes all scoping" do
          unscoped.selector.should be_empty
        end
      end
    end

    context "when used with a block" do

      context "when a criteria is called in the block" do

        it "does not allow default scoping to be added in the block" do
          Band.unscoped do
            empty.skip(10).selector.should be_empty
          end
        end
      end

      context "when a call is made to scoped in the block" do

        it "does not allow default scoping to be added in the block" do
          Band.unscoped do
            empty.scoped.selector.should be_empty
          end
        end
      end

      context "when a named scope is called in the block" do

        before do
          Band.scope(:skipped, Band.skip(10))
        end

        after do
          class << Band
            undef_method :skipped
          end
          Band._declared_scopes.clear
        end

        it "does not allow the default scope to be applied" do
          Band.unscoped do
            empty.skipped.selector.should be_empty
          end
        end
      end
    end
  end
end
