require "spec_helper"

describe Mongoid::Scopable do

  describe ".default_scope" do

    context "when provided a criteria" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      before do
        Band.default_scope criteria
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

    context "when provided a non proc or criteria" do

      it "raises an error" do
        expect {
          Band.default_scope({})
        }.to raise_error(Mongoid::Errors::InvalidScope)
      end
    end

    context "when there is more then one default_scope" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:additional_criteria) do
        Band.where(origin: "England")
      end

      let(:proc_criteria) do
        ->{ Band.where(active: true) }
      end

      let(:rand_criteria) do
        ->{ Band.gt(likes: rand(100)) }
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
        expect(Band.default_scoping.call.selector["active"]).to be_truthy
      end

      it "delays execution of the merge until called" do
        expect(Band.all.selector["likes"]).to_not eq(Band.all.selector["likes"])
      end

      it "flags as being default scoped" do
        expect(Band).to be_default_scoping
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
    end

    context "when a criteria exists on the stack" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      before do
        Band.scope_stack.push(criteria)
      end

      after do
        Band.scope_stack.clear
      end

      it "returns the criteria on the stack" do
        expect(Band.queryable).to eq(criteria)
      end
    end
  end

  describe ".scope" do

    context "when provided a criteria" do

      context "when a block is provided" do

        before do
          Band.scope(:active, Band.where(active: true)) do
            def add_origin
              tap { |c| c.selector[:origin] = "Deutschland" }
            end
          end
        end

        after do
          class << Band
            undef_method :active
          end
          Band._declared_scopes.clear
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
            Record.where(:name.in => [ "undertow", "aenima", "lateralus" ])
          )
        end

        after do
          class << Record
            undef_method :tool
          end
          Record._declared_scopes.clear
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
          Band.scope(:active, Band.where(active: true).skip(10))
        end

        after do
          class << Band
            undef_method :active
          end
          Band._declared_scopes.clear
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
              Band.scope(:english, Band.where(origin: "England"))
            end

            after do
              class << Band
                undef_method :english
              end
              Band._declared_scopes.clear
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

          before do
            Mongoid.scope_overwrite_exception = true
          end

          after do
            Mongoid.scope_overwrite_exception = false
            class << Band
              undef_method :active
            end
            Band._declared_scopes.clear
          end

          it "raises an exception" do
            expect {
              Band.scope(:active, Band.where(active: true))
              Band.scope(:active, Band.where(active: true))
            }.to raise_error(Mongoid::Errors::ScopeOverwrite)
          end
        end

        context "when not raising an error" do

          after do
            Mongoid.scope_overwrite_exception = false
            class << Band
              undef_method :active
            end
            Band._declared_scopes.clear
          end

          it "raises no exception" do
            Band.scope(:active, Band.where(active: true))
            Band.scope(:active, Band.where(active: true))
          end
        end
      end
    end

    context "when provided a proc" do

      context "when a block is provided" do

        before do
          Band.scope(:active, ->{ Band.where(active: true) }) do
            def add_origin
              tap { |c| c.selector[:origin] = "Deutschland" }
            end
          end
        end

        after do
          class << Band
            undef_method :active
          end
          Band._declared_scopes.clear
        end

        let(:scope) do
          Band.active.add_origin
        end

        it "adds the extension to the scope" do
          expect(scope.selector).to eq({ "active" => true, "origin" => "Deutschland" })
        end
      end

      context "when no block is provided" do

        before do
          Band.scope(:active, ->{ Band.where(active: true).skip(10) })
          Band.scope(:named_by, ->(name) { Band.where(name: name) if name })
        end

        after do
          class << Band
            undef_method :active
            undef_method :named_by
          end
          Band._declared_scopes.clear
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
              class << Band
                undef_method :english
              end
              Band._declared_scopes.clear
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

          before do
            Mongoid.scope_overwrite_exception = true
          end

          after do
            Mongoid.scope_overwrite_exception = false
            class << Band
              undef_method :active
            end
            Band._declared_scopes.clear
          end

          it "raises an exception" do
            expect {
              Band.scope(:active, ->{ Band.where(active: true) })
              Band.scope(:active, ->{ Band.where(active: true) })
            }.to raise_error(Mongoid::Errors::ScopeOverwrite)
          end
        end

        context "when not raising an error" do

          after do
            Mongoid.scope_overwrite_exception = false
            class << Band
              undef_method :active
            end
            Band._declared_scopes.clear
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

    context "when chaining a non proc with a proc" do

      context "when both scopes are or queries" do

        let(:time) do
          Time.now
        end

        before do
          Band.scope(:xxx, Band.any_of({ :aaa.gt => 0 }, { :bbb.gt => 0 }))
          Band.scope(:yyy, ->{ Band.any_of({ :ccc => nil }, { :ccc.gt => time }) })
        end

        after do
          class << Band
            undef_method :xxx
            undef_method :yyy
          end
          Band._declared_scopes.clear
        end

        let(:criteria) do
          Band.yyy.xxx
        end

        it "properly chains the $or queries together" do
          expect(criteria.selector).to eq({
            "$or" => [
              { "ccc" => nil },
              { "ccc" => { "$gt" => time }},
              { "aaa" => { "$gt" => 0.0 }},
              { "bbb" => { "$gt" => 0.0 }}
            ]
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
        class << Shape
          undef_method :located_at
        end
        Shape._declared_scopes.clear

        class << Circle
          undef_method :with_radius
        end
        Circle._declared_scopes.clear
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
  end

  describe ".scope_stack" do

    context "when the scope stack has not been accessed" do

      it "returns an empty array" do
        expect(Band.scope_stack).to eq([])
      end
    end

    context "when a criteria exists on the current thread" do

      let(:criteria) do
        Band.where(active: true)
      end

      before do
        Mongoid::Threaded.scope_stack[Band.object_id] = [ criteria ]
      end

      after do
        Mongoid::Threaded.scope_stack[Band.object_id].clear
      end

      it "returns the criteria in the array" do
        expect(Band.scope_stack).to eq([ criteria ])
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
        Band.default_scope criteria
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
      Band.default_scope criteria
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
      Band.default_scope criteria
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

    it "pops the criteria off the stack" do
      Band.with_scope(criteria) {}
      expect(Band.scope_stack).to be_empty
    end
  end

  describe ".without_default_scope" do

    it "sets the threading options" do
      Band.without_default_scope do
        expect(Mongoid::Threaded).to be_executing(:without_default_scope)
      end
    end
  end
end
