# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Scopable do

  describe "#apply_default_scope" do

    context "when the default scope has options" do

      let(:scope) do
        Band.skip(20)
      end

      before do
        Band.default_scope ->{ scope }
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
        expect(scoped.options).to eq({ skip: 20 })
      end

      it "sets scoped to true" do
        expect(scoped).to be_scoped
      end
    end

    context "when the default scope has selection" do

      let(:scope) do
        Band.where(name: "Depeche Mode")
      end

      before do
        Band.default_scope ->{ scope }
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
        expect(scoped.selector).to eq({ "name" => "Depeche Mode" })
      end

      it "sets scoped to true" do
        expect(scoped).to be_scoped
      end
    end

    context "when the default scope has inclusions" do

      let(:scope) do
        Band.includes(:records)
      end

      before do
        Band.default_scope ->{ scope }
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
          expect(scoped.inclusions).to eq(
            [ Band.relations["records"] ]
          )
        end

        it "sets scoped to true" do
          expect(scoped).to be_scoped
        end
      end

      context "when merging with a criteria that has inclusions" do

        let(:scoped) do
          Band.includes(:label).tap do |criteria|
            criteria.apply_default_scope
          end
        end

        it "merges in the inclusions" do
          expect(scoped.inclusions).to eq(
            [ Band.relations["records"], Band.relations["label"] ]
          )
        end

        it "sets scoped to true" do
          expect(scoped).to be_scoped
        end
      end
    end
  end

  describe "#apply_scope" do

    let(:criteria) do
      Band.skip(20).where(name: 'Black Sabbath').includes(:same_name)
    end

    let(:result) do
      criteria.apply_scope(scope)
    end

    context "when the scope is a Criteria" do

      context 'when standard scope' do
        let(:scope) do
          Band.gt(member_count: 3).limit(3).includes(:artists)
        end

        it 'merges the criteria' do
          expect(result.selector).to eq("name" => "Black Sabbath", "member_count" => { "$gt"=>3 })
          expect(result.options).to eq(skip: 20, limit: 3)
          expect(result.inclusions.map(&:name)).to eq(%i[same_name artists])
        end
      end

      context 'when unscoped' do
        let(:scope) do
          Band.unscoped.gt(member_count: 3).limit(3).includes(:artists)
        end

        it 'unscoped has no effect' do
          expect(result.selector).to eq("name" => "Black Sabbath", "member_count" => { "$gt"=>3 })
          expect(result.options).to eq(skip: 20, limit: 3)
          expect(result.inclusions.map(&:name)).to eq(%i[same_name artists])
        end
      end
    end

    context "when the scope is a Proc" do

      context 'when standard scope' do
        let(:scope) do
          -> { gt(member_count: 3).limit(3).includes(:artists) }
        end

        it 'adds the scope' do
          expect(result.selector).to eq("name" => "Black Sabbath", "member_count" => { "$gt"=>3 })
          expect(result.options).to eq(skip: 20, limit: 3)
          expect(result.inclusions.map(&:name)).to eq(%i[same_name artists])
        end
      end

      context 'when unscoped' do
        let(:scope) do
          -> { unscoped.gt(member_count: 3).limit(3).includes(:artists) }
        end

        it 'removes existing scopes then adds the new scope' do
          expect(result.selector).to eq("member_count" => { "$gt"=>3 })
          expect(result.options).to eq(limit: 3)
          expect(result.inclusions.map(&:name)).to eq(%i[same_name artists])
        end
      end
    end

    context "when the scope is a Symbol" do

      context 'when standard scope' do
        let(:scope) do
          :highly_rated
        end

        it 'adds the scope' do
          expect(result.selector).to eq("name" => "Black Sabbath", "rating" => { "$gte" => 7 })
          expect(result.options).to eq(skip: 20)
          expect(result.inclusions.map(&:name)).to eq(%i[same_name])
        end
      end

      context 'when unscoped' do
        let(:scope) do
          :unscoped
        end

        it 'removes existing scopes then adds the new scope' do
          expect(result.selector).to eq({})
          expect(result.options).to eq({})
          expect(result.inclusions.map(&:name)).to eq(%i[same_name])
        end
      end
    end

    context 'when model has default_scope' do

      before do
        Band.default_scope ->{ Band.where(active: true).includes(:records) }
      end

      after do
        Band.default_scoping = nil
      end

      context 'when standard scope' do
        let(:scope) do
          -> { gt(member_count: 3).limit(3).includes(:artists) }
        end

        it 'merges the scope' do
          expect(result.selector).to eq("active" => true, "name" => "Black Sabbath", "member_count" => { "$gt" => 3 })
          expect(result.options).to eq(skip: 20, limit: 3)
          expect(result.inclusions.map(&:name)).to eq(%i[records same_name artists])
        end
      end

      context 'when unscoped' do
        let(:scope) do
          -> { unscoped.gt(member_count: 3).limit(3).includes(:artists) }
        end

        it 'removes existing scopes then adds the new scope' do
          expect(result.selector).to eq("member_count" => { "$gt" => 3 })
          expect(result.options).to eq(limit: 3)
          expect(result.inclusions.map(&:name)).to eq(%i[records same_name artists])
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
        expect(criteria.selector).to be_empty
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
          expect(criteria.options).to be_empty
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
          expect(criteria.options).to be_empty
        end

        it "does not remove the selector" do
          expect(criteria.selector).to eq({ "name" => nil })
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
        expect(criteria.inclusions).to eq([ Band.relations["records"] ])
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
        expect(scoped).to be_a(Mongoid::Criteria)
      end

      it "contains an empty selector" do
        expect(scoped.selector).to be_empty
      end

      it "contains empty options" do
        expect(scoped.options).to be_empty
      end
    end

    context "when options are provided" do

      let(:scoped) do
        empty.scoped(skip: 10, limit: 10)
      end

      it "returns a criteria" do
        expect(scoped).to be_a(Mongoid::Criteria)
      end

      it "contains an empty selector" do
        expect(scoped.selector).to be_empty
      end

      it "contains the options" do
        expect(scoped.options).to eq({ skip: 10, limit: 10 })
      end
    end

    context "when a default scope exists" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      before do
        Band.default_scope ->{ criteria }
      end

      after do
        Band.default_scoping = nil
      end

      let(:scoped) do
        empty.scoped
      end

      it "allows the default scope to be added" do
        expect(scoped.selector).to eq({ "name" => "Depeche Mode" })
      end

      it "flags as scoped" do
        expect(scoped).to be_scoped
      end

      context "when chained after an unscoped criteria" do

        let(:scoped) do
          empty.unscoped.scoped
        end

        it "reapplies the default scope" do
          expect(scoped.selector).to eq({ "name" => "Depeche Mode" })
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
      expect(criteria.scoping_options).to eq([ true, false ])
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
      expect(criteria).to be_scoped
    end

    it "sets the unscoped flag" do
      expect(criteria).to be_unscoped
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
      Band.default_scope ->{ criteria }
    end

    after do
      Band.default_scoping = nil
    end

    context "when called directly" do

      let(:unscoped) do
        empty.unscoped
      end

      it "removes the default scope from the criteria" do
        expect(unscoped.selector).to be_empty
      end

      context "when chained after a scoped criteria" do

        let(:unscoped) do
          empty.scoped.unscoped
        end

        it "removes all scoping" do
          expect(unscoped.selector).to be_empty
        end
      end
    end

    context "when used with a block" do

      context "when a criteria is called in the block" do

        it "does not allow default scoping to be added in the block" do
          Band.unscoped do
            expect(empty.skip(10).selector).to be_empty
          end
        end
      end

      context "when a call is made to scoped in the block" do

        it "does not allow default scoping to be added in the block" do
          Band.unscoped do
            expect(empty.scoped.selector).to be_empty
          end
        end
      end

      context "when a named scope is called in the block" do

        before do
          Band.scope(:skipped, ->{ Band.skip(10) })
        end

        after do
          class << Band
            undef_method :skipped
          end
          Band._declared_scopes.clear
        end

        it "does not allow the default scope to be applied" do
          Band.unscoped do
            expect(empty.skipped.selector).to be_empty
          end
        end
      end
    end
  end

  describe 'scope and where' do
    class ScopeWhereModel
      include Mongoid::Document

      scope :foo, -> { where(foo: true) }
    end

    shared_examples_for 'restricts to both' do
      it 'restricts to both' do
        expect(result.selector['foo']).to eq(true)
        expect(result.selector['hello']).to eq('world')
      end
    end

    context 'scope is given first' do
      let(:result) { ScopeWhereModel.foo.where(hello: 'world') }

      it_behaves_like 'restricts to both'
    end

    context 'where is given first' do
      let(:result) { ScopeWhereModel.where(hello: 'world').foo }

      it_behaves_like 'restricts to both'
    end
  end

  describe 'scope with argument and where' do
    class ArgumentScopeWhereModel
      include Mongoid::Document

      scope :my_text_search, ->(search) { where('$text' => {'$search' => search}) }
    end

    shared_examples_for 'restricts to both' do
      it 'restricts to both' do
        expect(result.selector['$text']).to eq({'$search' => 'bar'})
        expect(result.selector['hello']).to eq('world')
      end
    end

    context 'scope is given first' do
      let(:result) { ArgumentScopeWhereModel.my_text_search('bar').where(hello: 'world') }

      it_behaves_like 'restricts to both'
    end

    context 'where is given first' do
      let(:result) { ArgumentScopeWhereModel.where(hello: 'world').my_text_search('bar') }

      it_behaves_like 'restricts to both'
    end
  end

  describe 'built in text search scope and where' do
    class TextSearchScopeWhereModel
      include Mongoid::Document

      # using the default text_search scope
    end

    shared_examples_for 'restricts to both' do
      it 'restricts to both' do
        expect(result.selector['$text']).to eq({'$search' => 'bar'})
        expect(result.selector['hello']).to eq('world')
      end
    end

    context 'scope is given first' do
      let(:result) { TextSearchScopeWhereModel.text_search('bar').where(hello: 'world') }

      it_behaves_like 'restricts to both'
    end

    context 'where is given first' do
      let(:result) { TextSearchScopeWhereModel.where(hello: 'world').text_search('bar') }

      it_behaves_like 'restricts to both'
    end
  end
end
