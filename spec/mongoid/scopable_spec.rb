# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

# Retrieve the singleton class for the given class.
def singleton_class_for(klass)
  class <<klass; self; end
end

# Helper method for removing a declared scope
def remove_scope(klass, scope)
  if klass._declared_scopes[scope]
    singleton_class_for(klass).remove_method(scope)
    klass._declared_scopes.delete(scope)
  end
end

describe Mongoid::Scopable do

  describe ".default_scope" do

    context "when provided a proc" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      before do
        Band.default_scope ->{ criteria }
      end

      after do
        Band.default_scoping = nil
      end

      it "adds the default scope to the class" do
        expect(Band.default_scoping.call).to eq(criteria)
      end

      it "flags as being default scoped" do
        expect(Band).to be_default_scoping
      end
    end

    context "when provided a block" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      before do
        Band.default_scope { criteria }
      end

      after do
        Band.default_scoping = nil
      end

      it "adds the default scope to the class" do
        expect(Band.default_scoping.call).to eq(criteria)
      end

      it "flags as being default scoped" do
        expect(Band).to be_default_scoping
      end
    end

    context "when a class method" do
      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      before do
        class DefaultScopeAsClassMethod
          include Mongoid::Document

          def self.default_scope
            criteria
          end
        end
      end

      after do
        Mongoid.deregister_model(DefaultScopeAsClassMethod)
        Object.send(:remove_const, :DefaultScopeAsClassMethod)
      end

      it "adds the default scope to the class" do
        pending 'https://jira.mongodb.org/browse/MONGOID-5483'
        expect(DefaultScopeAsClassMethod.default_scoping.call).to eq(criteria)
      end

      it "flags as being default scoped" do
        pending 'https://jira.mongodb.org/browse/MONGOID-5483'
        expect(DefaultScopeAsClassMethod).to be_default_scoping
      end
    end

    context "when provided a non proc" do

      it "raises an error" do
        expect {
          Band.default_scope({})
        }.to raise_error(Mongoid::Errors::InvalidScope)
      end
    end

    context "when there is more then one default_scope" do

      let(:criteria) do
        ->{ Band.where(name: "Depeche Mode") }
      end

      let(:additional_criteria) do
        ->{ Band.where(origin: "England") }
      end

      let(:proc_criteria) do
        ->{ Band.where(active: true) }
      end

      let(:rand_criteria) do
        ->{ Band.gt(likes: Mongo::Monitoring.next_operation_id) }
      end

      before do
        Band.default_scope criteria
        Band.default_scope additional_criteria
        Band.default_scope proc_criteria
        Band.default_scope rand_criteria
      end

      after do
        Band.default_scoping = nil
      end

      it "adds the first default scope" do
        expect(Band.default_scoping.call.selector["name"]).to eq("Depeche Mode")
      end

      it "adds the additional default scope" do
        expect(Band.default_scoping.call.selector["origin"]).to eq("England")
      end

      it "adds the proc default scope" do
        expect(Band.default_scoping.call.selector["active"]).to be true
      end

      it "delays execution of the merge until called" do
        expect(Band.all.selector["likes"]).to_not eq(Band.all.selector["likes"])
      end

      it "flags as being default scoped" do
        expect(Band).to be_default_scoping
      end
    end

    context "when parent class has default scope" do

      let (:selector) do
        AudibleSound.all.selector
      end

      it "the subclass doesn't duplicate the default scope in the selector" do
        expect(selector).to eq({'active' => true})
      end
    end

    context "when the default scope is dotted" do

      let(:criteria) do
        Band.where('tags.foo' => 'bar')
      end

      before do
        Band.default_scope ->{ criteria }
      end

      after do
        Band.default_scoping = nil
      end

      let!(:band) do
        Band.create!
      end

      it "adds the scope as a dotted key attribute" do
        expect(band.attributes['tags.foo']).to eq('bar')
      end

      it "adds the default scope to the class" do
        expect(Band.default_scoping.call).to eq(criteria)
      end

      it "flags as being default scoped" do
        expect(Band).to be_default_scoping
      end

      it "does not find the correct document" do
        expect(Band.count).to eq(0)
      end
    end

    context "when the default scope is dotted with a query" do

      let(:criteria) do
        Band.where('tags.foo' => {'$eq' => 'bar'})
      end

      before do
        Band.default_scope ->{ criteria }
      end

      after do
        Band.default_scoping = nil
      end

      let!(:band) do
        Band.create!('tags' => { 'foo' => 'bar' })
      end

      it "does not add the scope as a dotted key attribute" do
        expect(band.attributes).to_not have_key('tags.foo')
      end

      it "adds the default scope to the class" do
        expect(Band.default_scoping.call).to eq(criteria)
      end

      it "flags as being default scoped" do
        expect(Band).to be_default_scoping
      end

      it "finds the correct document" do
        expect(Band.where.first).to eq(band)
      end
    end
  end

  describe ".default_scopable?" do

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

      context "when not in an unscoped block" do

        it "returns true" do
          expect(Band).to be_default_scopable
        end
      end

      context "when in an unscoped block" do

        it "returns false" do
          Band.unscoped do
            expect(Band).to_not be_default_scopable
          end
        end
      end
    end

    context "when a default scope does not exist" do

      it "returns false" do
        expect(Band).to_not be_default_scopable
      end
    end
  end

  describe ".queryable" do

    context "when no criteria exists on the stack" do

      it "returns an empty criteria" do
        expect(Band.queryable.selector).to be_empty
      end

      context "when the class is not embedded" do

        it "returns a criteria with embedded set to nil" do
          expect(Band.queryable.embedded).to be(nil)
        end
      end

      context "when the class is embedded" do

        it "returns a criteria with embedded set to true" do
          expect(Address.queryable.embedded).to be(true)
        end

        context "when scopes are chained" do

          let(:person) do
            Person.create!
          end

          it "constructs a criteria for an embedded relation" do
            expect(person.addresses.without_postcode_ordered.embedded).to be(true)
          end
        end
      end
    end

    context "when a criteria exists on the stack" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      context "when using #current_scope=scope" do

        before do
          Mongoid::Threaded.current_scope = criteria
        end

        after do
          Mongoid::Threaded.current_scope = nil
        end

        it "returns the criteria on the stack" do
          expect(Band.queryable).to eq(criteria)
        end
      end

      context "when using #set_current_scope(scope, klass)" do

        before do
          Mongoid::Threaded.set_current_scope(criteria, Band)
        end

        after do
          Mongoid::Threaded.set_current_scope(nil, Band)
        end

        it "returns the criteria on the stack" do
          expect(Band.queryable).to eq(criteria)
        end
      end
    end
  end

  describe ".scope" do

    context "when provided a criteria" do

      context 'when a collation is defined on the criteria' do

        before do
          Band.scope(:tests, ->{ Band.where(name: 'TESTING').collation(locale: 'en_US', strength: 2) })
          Band.create!(name: 'testing')
        end

        after do
          remove_scope(Band, :tests)
        end

        it 'applies the collation' do
          expect(Band.tests.first['name']).to eq('testing')
        end
      end

      context "when a block is provided" do

        before do
          Band.scope(:active, ->{ Band.where(active: true) }) do
            def add_origin
              tap { |c| c.selector[:origin] = "Deutschland" }
            end
          end
        end

        after do
          remove_scope(Band, :active)
        end

        let(:scope) do
          Band.active.add_origin
        end

        it "adds the extension to the scope" do
          expect(scope.selector).to eq({ "active" => true, "origin" => "Deutschland" })
        end
      end

      context "when scoping an embedded document" do

        before do
          Record.scope(
            :tool,
            ->{ Record.where(:name.in => [ "undertow", "aenima", "lateralus" ]) }
          )
        end

        after do
          remove_scope(Record, :tool)
        end

        context "when calling the scope" do

          let(:band) do
            Band.new
          end

          let!(:undertow) do
            band.records.build(name: "undertow")
          end

          let(:scoped) do
            band.records.tool
          end

          it "returns the correct documents" do
            expect(scoped).to eq([ undertow ])
          end
        end
      end

      context "when no block is provided" do

        before do
          Band.scope(:active, ->{ Band.where(active: true).skip(10) })
        end

        after do
          remove_scope(Band, :active)
        end

        it "adds a method for the scope" do
          expect(Band).to respond_to(:active)
        end

        context "when calling the scope" do

          context "when calling from the class" do

            let(:scope) do
              Band.active
            end

            it "returns a criteria" do
              expect(scope).to be_a(Mongoid::Criteria)
            end

            it "contains the proper selector" do
              expect(scope.selector).to eq({ "active" => true })
            end

            it "contains the proper options" do
              expect(scope.options).to eq({ skip: 10 })
            end
          end

          context "when chained to another scope" do

            before do
              Band.scope(:english, ->{ Band.where(origin: "England") })
            end

            after do
              remove_scope(Band, :english)
            end

            let(:scope) do
              Band.english.active
            end

            it "returns a criteria" do
              expect(scope).to be_a(Mongoid::Criteria)
            end

            it "contains the proper selector" do
              expect(scope.selector).to eq({ "active" => true, "origin" => "England" })
            end

            it "contains the proper options" do
              expect(scope.options).to eq({ skip: 10 })
            end

            it "does not modify the original scope" do
              expect(Band.active.selector).to eq({ "active" => true })
            end
          end

          context "when chained to a criteria" do

            let(:criteria) do
              Band.where(origin: "England")
            end

            let(:scope) do
              criteria.active
            end

            it "returns a criteria" do
              expect(scope).to be_a(Mongoid::Criteria)
            end

            it "contains the proper selector" do
              expect(scope.selector).to eq({ "origin" => "England", "active" => true })
            end

            it "contains the proper options" do
              expect(scope.options).to eq({ skip: 10 })
            end

            it "does not modify the original scope" do
              expect(Band.active.selector).to eq({ "active" => true })
            end

            it "does not modify the original criteria" do
              expect(criteria.selector).to eq({ "origin" => "England" })
            end
          end
        end
      end

      context "when the name conflict with an existing method" do

        context "when raising an error" do
          config_override :scope_overwrite_exception, true

          after do
            remove_scope(Band, :active)
          end

          it "raises an exception" do
            expect {
              Band.scope(:active, ->{ Band.where(active: true) })
              Band.scope(:active, ->{ Band.where(active: true) })
            }.to raise_error(Mongoid::Errors::ScopeOverwrite)
          end
        end

        context "when not raising an error" do
          config_override :scope_overwrite_exception, false

          after do
            remove_scope(Band, :active)
          end

          it "raises no exception" do
            Band.scope(:active, ->{ Band.where(active: true) })
            Band.scope(:active, ->{ Band.where(active: true) })
          end
        end
      end
    end

    context "when provided a proc" do

      context "when a block is provided" do

        context "when with optional and keyword arguments" do
          before do
            Band.scope(:named_by, ->(name, deleted: false) {
              Band.where(name: name, deleted: deleted)
            })
          end

          let(:scope) do
            Band.named_by("Emily", deleted: true)
          end

          it "sets the conditions from keyword arguments" do
            scope.selector.should == {'name' => 'Emily', 'deleted' => true}
          end
        end

        context "when without arguments" do
          before do
            Band.scope(:active, ->{ Band.where(active: true) }) do
              def add_origin
                tap { |c| c.selector[:origin] = "Deutschland" }
              end
            end
          end

          after do
            remove_scope(Band, :active)
          end

          let(:scope) do
            Band.active.add_origin
          end

          it "adds the extension to the scope" do
            expect(scope.selector).to eq({ "active" => true, "origin" => "Deutschland" })
          end
        end
      end

      context 'when the block is an none scope' do

        before do
          Simple.create!(name: 'Emily')
        end

        context 'when there is no default scope' do

          before do
            Simple.scope(:nothing, ->{ none })
          end

          it 'returns no results' do
            expect(Simple.nothing).to be_empty
          end
        end

        context 'when there is a default scope' do

          let(:criteria) do
            Simple.where(name: "Emily")
          end

          before do
            Simple.default_scope ->{ criteria }
            Simple.scope(:nothing, ->{ none })
          end

          after do
            Simple.default_scoping = nil
          end

          it 'returns no results' do
            expect(Simple.nothing).to be_empty
          end
        end

      end

      context "when no block is provided" do

        before do
          Band.scope(:active, ->{ Band.where(active: true).skip(10) })
          Band.scope(:named_by, ->(name) { Band.where(name: name) if name })
        end

        after do
          remove_scope(Band, :active)
          remove_scope(Band, :named_by)
        end

        it "adds a method for the scope" do
          expect(Band).to respond_to(:active)
        end

        context "when calling the scope" do

          context "when the scope would return nil" do

            it "returns a chainable empty scope" do
              expect(Band.named_by(nil)).to be_a(Mongoid::Criteria)
            end
          end

          context "when calling from the class" do

            let(:scope) do
              Band.active
            end

            it "returns a criteria" do
              expect(scope).to be_a(Mongoid::Criteria)
            end

            it "contains the proper selector" do
              expect(scope.selector).to eq({ "active" => true })
            end

            it "contains the proper options" do
              expect(scope.options).to eq({ skip: 10 })
            end
          end

          context "when chained to another scope" do

            before do
              Band.scope(:english, ->{ Band.where(origin: "England") })
            end

            after do
              remove_scope(Band, :english)
            end

            let(:scope) do
              Band.english.active
            end

            it "returns a criteria" do
              expect(scope).to be_a(Mongoid::Criteria)
            end

            it "contains the proper selector" do
              expect(scope.selector).to eq({ "active" => true, "origin" => "England" })
            end

            it "contains the proper options" do
              expect(scope.options).to eq({ skip: 10 })
            end

            it "does not modify the original scope" do
              expect(Band.active.selector).to eq({ "active" => true })
            end
          end

          context "when chained to a criteria" do

            let(:criteria) do
              Band.where(origin: "England")
            end

            let(:scope) do
              criteria.active
            end

            it "returns a criteria" do
              expect(scope).to be_a(Mongoid::Criteria)
            end

            it "contains the proper selector" do
              expect(scope.selector).to eq({ "origin" => "England", "active" => true })
            end

            it "contains the proper options" do
              expect(scope.options).to eq({ skip: 10 })
            end

            it "does not modify the original scope" do
              expect(Band.active.selector).to eq({ "active" => true })
            end

            it "does not modify the original criteria" do
              expect(criteria.selector).to eq({ "origin" => "England" })
            end
          end

          context "when chaining scopes through more than one model" do

            before do
              Author.scope(:author, -> { where(author: true) } )
              Article.scope(:is_public, -> { where(public: true) } )
              Article.scope(:authored, -> {
                author_ids = Author.author.pluck(:id)
                where(:author_id.in => author_ids)
              })

              Author.create!(author: true, id: 1)
              Author.create!(author: true, id: 2)
              Author.create!(author: true, id: 3)
              Article.create!(author_id: 1, public: true)
              Article.create!(author_id: 2, public: true)
              Article.create!(author_id: 3, public: false)
            end

            after do
              remove_scope(Article, :is_public)
              remove_scope(Article, :authored)
              remove_scope(Author, :author)
            end

            context "when calling another model's scope from within a scope" do

              let(:authored_count) do
                Article.authored.size
              end

              it "returns the correct documents" do
                expect(authored_count).to eq(3)
              end
            end

            context "when calling another model's scope from within a chained scope" do
              let(:is_public_authored_count) do
                Article.is_public.authored.size
              end

              it "returns the correct documents" do
                expect(is_public_authored_count).to eq(2)
              end
            end
          end
        end
      end

      context "when the name conflict with an existing method" do

        context "when raising an error" do
          config_override :scope_overwrite_exception, true

          after do
            remove_scope(Band, :active)
          end

          it "raises an exception" do
            expect {
              Band.scope(:active, ->{ Band.where(active: true) })
              Band.scope(:active, ->{ Band.where(active: true) })
            }.to raise_error(Mongoid::Errors::ScopeOverwrite)
          end
        end

        context "when not raising an error" do
          config_override :scope_overwrite_exception, false

          after do
            remove_scope(Band, :active)
          end

          it "raises no exception" do
            Band.scope(:active, ->{ Band.where(active: true) })
            Band.scope(:active, ->{ Band.where(active: true) })
          end
        end
      end
    end

    context "when provided a non proc or criteria" do

      it "raises an error" do
        expect {
          Band.scope(:active, {})
        }.to raise_error(Mongoid::Errors::InvalidScope)
      end
    end

    context "when chaining a proc with a proc" do

      context "when both scopes are or queries" do

        before do
          Band.scope(:xxx, ->{ Band.any_of({ :aaa.gt => 0 }, { :bbb.gt => 0 }) })
          Band.scope(:yyy, ->{ Band.any_of({ :ccc => nil }, { :ccc.gt => 1 }) })
        end

        after do
          remove_scope(Band, :xxx)
          remove_scope(Band, :yyy)
        end

        let(:criteria) do
          Band.yyy.xxx
        end

        it "properly chains the $or queries together" do
          expect(criteria.selector).to eq({
            "$or" => [
              { "ccc" => nil },
              { "ccc" => { "$gt" => 1.0 }},
            ],
            '$and' => ['$or' => [
              { "aaa" => { "$gt" => 0.0 }},
              { "bbb" => { "$gt" => 0.0 }}
            ]],
          })
        end
      end
    end

    context "when working with a subclass" do

      before do
        Shape.scope(:located_at, ->(x,y) {Shape.where(x: x, y: y)})
        Circle.scope(:with_radius, ->(r) {Circle.where(radius: r)})
      end

      after do
        remove_scope(Shape, :located_at)
        remove_scope(Circle, :with_radius)
      end

      let(:shape_scope_keys) do
        Shape.scopes.keys
      end

      let(:circle_located_at) do
        Circle.located_at(0,0)
      end

      let(:circle_scope_keys) do
        Circle.scopes.keys
      end

      it "doesn't include subclass scopes in superclass scope list" do
        expect(shape_scope_keys).to match_array([:located_at])
      end

      it "includes superclass scope methods on subclass" do
        expect(circle_located_at).to be_a(Mongoid::Criteria)
      end

      it "includes superclass scopes in subclass scope list" do
        expect(circle_scope_keys).to match_array([:located_at, :with_radius])
      end
    end

    context "when calling a scope defined in a parent class" do

      before do
        Shape.class_eval do
          scope :visible, -> { large }
          scope :large, -> { all }
        end
        Circle.class_eval do
          scope :large, -> { where(radius: 5) }
        end
      end

      after do
        remove_scope(Shape, :visible)
        remove_scope(Shape, :large)
        remove_scope(Circle, :large)
      end

      it "uses subclass context for all the other used scopes" do
        expect(Circle.visible.selector).to eq("radius" => 5)
      end
    end
  end

  describe ".scoped" do

    context "when no options are provided" do

      let(:scoped) do
        Band.scoped
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
        Band.scoped(skip: 10, limit: 10)
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
        Band.scoped
      end

      it "allows the default scope to be added" do
        expect(scoped.selector).to eq({ "name" => "Depeche Mode" })
      end

      context "when chained after an unscoped criteria" do

        let(:scoped) do
          Band.unscoped.scoped
        end

        it "reapplies the default scope" do
          expect(scoped.selector).to eq({ "name" => "Depeche Mode" })
        end
      end
    end
  end

  describe ".unscoped" do

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
        Band.unscoped
      end

      it "removes the default scope from the criteria" do
        expect(unscoped.selector).to be_empty
      end

      context "when chained after a scoped criteria" do

        let(:unscoped) do
          Band.scoped.unscoped
        end

        it "removes all scoping" do
          expect(unscoped.selector).to be_empty
        end
      end

      context "when default scope is in a super class" do

        context "when scope is already defined in parent class" do

          let(:unscoped) do
            class U1 < Kaleidoscope; end
            U1.unscoped.activated
          end

          it "clears default scope" do
            expect(unscoped.selector).to eq({ "active" => true })
          end
        end

        context "when the scope is created dynamically" do

          before do
            Band.scope(:active, ->{ Band.where(active: true) })
          end

          after do
            remove_scope(Band, :active)
          end

          let(:unscoped) do
            class U2 < Band; end
            U2.unscoped.active
          end

          it "clears default scope" do
            expect(unscoped.selector).to eq({ "active" => true })
          end
        end
      end
    end

    context "when used with a block" do

      context "when a criteria is called in the block" do

        it "does not allow default scoping to be added in the block" do
          Band.unscoped do
            expect(Band.skip(10).selector).to be_empty
          end
        end
      end

      context "when a call is made to scoped in the block" do

        it "does not allow default scoping to be added in the block" do
          Band.unscoped do
            expect(Band.scoped.selector).to be_empty
          end
        end
      end

      context "when a named scope is called in the block" do

        before do
          Band.scope(:skipped, ->{ Band.skip(10) })
        end

        after do
          remove_scope(Band, :skipped)
        end

        it "does not allow the default scope to be applied" do
          Band.unscoped do
            expect(Band.skipped.selector).to be_empty
          end
        end
      end
    end
  end

  describe ".with_default_scope" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    before do
      Band.default_scope ->{ criteria }
    end

    after do
      Band.default_scoping = nil
    end

    context "when inside an unscoped block" do

      it "returns an empty criteria" do
        Band.unscoped do
          expect(Band.with_default_scope.selector).to be_empty
        end
      end
    end

    context "when the criteria is unscoped" do

      let(:scoped) do
        Band.unscoped.with_default_scope
      end

      it "returns an empty criteria" do
        expect(scoped.selector).to be_empty
      end
    end

    context "when no unscoping exists" do

      let(:scoped) do
        Band.with_default_scope
      end

      it "returns a scoped criteria" do
        expect(scoped.selector).to eq({ "name" => "Depeche Mode" })
      end
    end
  end

  describe ".with_scope" do

    let(:criteria) do
      Band.where(active: true)
    end

    it "yields to the criteria" do
      Band.with_scope(criteria) do |crit|
        expect(crit.selector).to eq({ "active" => true })
      end
    end

    context "when using #current_scope" do

      it "pops the criteria off the stack" do
        Band.with_scope(criteria) do;end
        expect(Mongoid::Threaded.current_scope).to be_nil
      end
    end

    context "when using #current_scope(klass)" do

      it "pops the criteria off the stack" do
        Band.with_scope(criteria) do;end
        expect(Mongoid::Threaded.current_scope(Band)).to be_nil
      end
    end

    context 'when nesting with_scope calls' do
      let(:c1) { Band.where(active: true) }
      let(:c2) { Band.where(active: false) }

      it 'restores previous scope' do
        Band.with_scope(c1) do |crit|
          Band.with_scope(c2) do |crit2|
            Mongoid::Threaded.current_scope(Band).selector.should == {
              'active' => true,
              '$and' => ['active' => false],
            }
          end

          Mongoid::Threaded.current_scope(Band).selector.should == {
            'active' => true,
          }
        end
      end
    end

    context 'when nesting unscoped under with_scope' do
      let(:c1) { Band.where(active: true) }

      it 'restores previous scope' do
        Band.with_scope(c1) do |crit|
          Band.unscoped do |crit2|
            Mongoid::Threaded.current_scope(Band).should be nil
          end

          Mongoid::Threaded.current_scope(Band).selector.should == {
            'active' => true,
          }
        end
      end
    end
  end

  describe ".without_default_scope" do

    it "sets the threading options" do
      Band.without_default_scope do
        expect(Mongoid::Threaded).to be_executing(:without_default_scope)
        expect(Mongoid::Threaded.without_default_scope?(Band)).to be(true)
      end
    end

    it "suppresses default scope on the given model within the given block" do
      Appointment.without_default_scope do
        expect(Appointment.all.selector).to be_empty
      end
    end

    it "does not affect other models' default scopes within the given block" do
      Appointment.without_default_scope do
        expect(Audio.all.selector).not_to be_empty
      end
    end
  end

  describe "scoped queries" do
    context "with a default scope" do
      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      before do
        Band.default_scope ->{ criteria }
        Band.scope :unscoped_everyone, -> { unscoped }
        Band.scope :removed_default, -> { scoped.remove_scoping(all) }

        Band.create name: 'Depeche Mode'
        Band.create name: 'They Might Be Giants'
      end

      after do
        Band.default_scoping = nil
        remove_scope Band, :unscoped_everyone
        remove_scope Band, :removed_default
      end

      context "when allow_scopes_to_unset_default_scope == false" do # default for <= 9
        config_override :allow_scopes_to_unset_default_scope, false

        it 'merges the default scope into the query with unscoped' do
          expect(Band.unscoped_everyone.selector).to include('name' => 'Depeche Mode')
        end

        it 'merges the default scope into the query with remove_scoping' do
          expect(Band.removed_default.selector).to include('name' => 'Depeche Mode')
        end
      end

      context "when allow_scopes_to_unset_default_scope == true" do # default for >= 10
        config_override :allow_scopes_to_unset_default_scope, true

        it 'does not merge the default scope into the query with unscoped' do
          expect(Band.unscoped_everyone.selector).not_to include('name' => 'Depeche Mode')
        end

        it 'does not merge merges the default scope into the query with remove_scoping' do
          expect(Band.removed_default.selector).not_to include('name' => 'Depeche Mode')
        end
      end
    end
  end
end
