# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Queryable::Selectable do

  let(:query) do
    Mongoid::Query.new("id" => "_id")
  end

  shared_examples_for 'logical combination' do
    context 'when argument is a Criteria' do
      let(:query) do
        Mongoid::Query.new.where(hello: 'world')
      end

      let(:other) do
        Mongoid::Query.new.where(foo: 'bar')
      end

      let(:result) { query.send(tested_method, other) }

      it 'combines' do
        expect(result.selector).to eq('hello' => 'world', expected_operator => [{'foo' => 'bar'}])
      end
    end

    context 'when argument is a mix of Criteria and hashes' do
      let(:query) do
        Mongoid::Query.new.where(hello: 'world')
      end

      let(:other1) do
        Mongoid::Query.new.where(foo: 'bar')
      end

      let(:other2) do
        {bar: 42}
      end

      let(:other3) do
        Mongoid::Query.new.where(a: 2)
      end

      let(:result) { query.send(tested_method, other1, other2, other3) }

      it 'combines' do
        expect(result.selector).to eq('hello' => 'world', expected_operator => [
          {'foo' => 'bar'},
          {'bar' => 42},
          {'a' => 2},
        ])
      end
    end
  end

  describe "#and" do

    context "when provided no criterion" do

      let(:selection) do
        query.and
      end

      it "does not add any criterion" do
        expect(selection.selector).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it "returns a cloned query" do
        expect(selection).to_not equal(query)
      end
    end

    context "when provided nil" do

      let(:selection) do
        query.and(nil)
      end

      it "does not add any criterion" do
        expect(selection.selector).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it "returns a cloned query" do
        expect(selection).to_not equal(query)
      end
    end

    context "when provided a single criterion" do

      let(:selection) do
        query.and(field: [ 1, 2 ])
      end

      it "adds the $and selector" do
        expect(selection.selector).to eq({
          "$and" => [{ "field" => [ 1, 2 ] }]
        })
      end

      it "returns a cloned query" do
        expect(selection).to_not equal(query)
      end
    end

    context "when provided a nested criterion" do

      let(:selection) do
        query.and(:test.elem_match => { :field.in => [ 1, 2 ] })
      end

      it "adds the $and selector" do
        expect(selection.selector).to eq({
          "$and" => [{ "test" => { "$elemMatch" => { "field" => { "$in" => [ 1, 2 ] }}}}]
        })
      end

      it "returns a cloned query" do
        expect(selection).to_not equal(query)
      end
    end

    context "when provided multiple criteria" do

      context "when the criteria is already included" do

        let(:selection) do
          query.and({ first: [ 1, 2 ] }).and({ first: [ 1, 2 ] })
        end

        it "does not duplicate the $and selector" do
          expect(selection.selector).to eq({
            "$and" => [
              { "first" => [ 1, 2 ] }
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end

      context "when the criteria is for different fields" do

        let(:selection) do
          query.and({ first: [ 1, 2 ] }, { second: [ 3, 4 ] })
        end

        it "adds the $and selector" do
          expect(selection.selector).to eq({
            "$and" => [
              { "first" => [ 1, 2 ] },
              { "second" => [ 3, 4 ] }
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end

      context "when the criteria are on the same field" do

        let(:selection) do
          query.and({ first: [ 1, 2 ] }, { first: [ 3, 4 ] })
        end

        it "appends both $and expressions" do
          expect(selection.selector).to eq({
            "$and" => [
              { "first" => [ 1, 2 ] },
              { "first" => [ 3, 4 ] }
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end
    end

    context "when chaining the criteria" do

      context "when the criteria are for different fields" do

        let(:selection) do
          query.and(first: [ 1, 2 ]).and(second: [ 3, 4 ])
        end

        it "adds the $and selectors" do
          expect(selection.selector).to eq({
            "$and" => [
              { "first" => [ 1, 2 ] },
              { "second" => [ 3, 4 ] }
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end

      context "when the criteria are on the same field" do

        let(:selection) do
          query.and(first: [ 1, 2 ]).and(first: [ 3, 4 ])
        end

        it "appends both $and expressions" do
          expect(selection.selector).to eq({
            "$and" => [
              { "first" => [ 1, 2 ] },
              { "first" => [ 3, 4 ] }
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when argument is a Criteria' do
      let(:tested_method) { :and }
      let(:expected_operator) { '$and' }

      it_behaves_like 'logical combination'
    end
  end

  describe "#or" do

    context "when provided no criterion" do

      let(:selection) do
        query.or
      end

      it "does not add any criterion" do
        expect(selection.selector).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it "returns a cloned query" do
        expect(selection).to_not equal(query)
      end
    end

    context "when provided nil" do

      let(:selection) do
        query.or(nil)
      end

      it "does not add any criterion" do
        expect(selection.selector).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it "returns a cloned query" do
        expect(selection).to_not equal(query)
      end
    end

    context "when provided a single criterion" do

      let(:selection) do
        query.or(field: [ 1, 2 ])
      end

      it "adds the $or selector" do
        expect(selection.selector).to eq({
          "$or" => [{ "field" => [ 1, 2 ] }]
        })
      end

      it "returns a cloned query" do
        expect(selection).to_not equal(query)
      end
    end

    context "when provided multiple criteria" do

      context "when the criteria are for different fields" do

        let(:selection) do
          query.or({ first: [ 1, 2 ] }, { second: [ 3, 4 ] })
        end

        it "adds the $or selector" do
          expect(selection.selector).to eq({
            "$or" => [
              { "first" => [ 1, 2 ] },
              { "second" => [ 3, 4 ] }
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end

      context "when the criteria has a selectable key" do

        let(:selection) do
          query.or({ first: [ 1, 2 ] }, { :second.gt => 3 })
        end

        it "adds the $or selector" do
          expect(selection.selector).to eq({
            "$or" => [
              { "first" => [ 1, 2 ] },
              { "second" => { "$gt" => 3 }}
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end

      context "when a criterion has an aliased field" do

        let(:selection) do
          query.or({ id: 1 })
        end

        it "adds the $or selector and aliases the field" do
          expect(selection.selector).to eq({
            "$or" => [ { "_id" => 1 } ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end

      context "when a criterion is wrapped in an array" do

        let(:selection) do
          query.or([{ first: [ 1, 2 ] }, { :second.gt => 3 }])
        end

        it "adds the $or selector" do
          expect(selection.selector).to eq({
            "$or" => [
              { "first" => [ 1, 2 ] },
              { "second" => { "$gt" => 3 }}
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end

      context "when the criteria are on the same field" do

        let(:selection) do
          query.or({ first: [ 1, 2 ] }, { first: [ 3, 4 ] })
        end

        it "appends both $or expressions" do
          expect(selection.selector).to eq({
            "$or" => [
              { "first" => [ 1, 2 ] },
              { "first" => [ 3, 4 ] }
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end
    end

    context "when chaining the criterion" do

      context "when the criterion are for different fields" do

        let(:selection) do
          query.or(first: [ 1, 2 ]).or(second: [ 3, 4 ])
        end

        it "adds the $or selectors" do
          expect(selection.selector).to eq({
            "$or" => [
              { "first" => [ 1, 2 ] },
              { "second" => [ 3, 4 ] }
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end

      context "when the criterion are on the same field" do

        let(:selection) do
          query.or(first: [ 1, 2 ]).or(first: [ 3, 4 ])
        end

        it "appends both $or expressions" do
          expect(selection.selector).to eq({
            "$or" => [
              { "first" => [ 1, 2 ] },
              { "first" => [ 3, 4 ] }
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when argument is a Criteria' do
      let(:tested_method) { :or }
      let(:expected_operator) { '$or' }

      it_behaves_like 'logical combination'
    end
  end

  describe "#nor" do

    context "when provided no criterion" do

      let(:selection) do
        query.nor
      end

      it "does not add any criterion" do
        expect(selection.selector).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it "returns a cloned query" do
        expect(selection).to_not equal(query)
      end
    end

    context "when provided nil" do

      let(:selection) do
        query.nor(nil)
      end

      it "does not add any criterion" do
        expect(selection.selector).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it "returns a cloned query" do
        expect(selection).to_not equal(query)
      end
    end

    context "when provided a single criterion" do

      let(:selection) do
        query.nor(field: [ 1, 2 ])
      end

      it "adds the $nor selector" do
        expect(selection.selector).to eq({
          "$nor" => [{"field" => [ 1, 2 ] }]
        })
      end

      it "returns a cloned query" do
        expect(selection).to_not equal(query)
      end
    end

    context "when provided multiple criterion" do

      context "when the criterion are fnor different fields" do

        let(:selection) do
          query.nor({ first: [ 1, 2 ] }, { second: [ 3, 4 ] })
        end

        it "adds the $nor selector" do
          expect(selection.selector).to eq({
            "$nor" => [
              { "first" => [ 1, 2 ] },
              { "second" => [ 3, 4 ] }
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end

      context "when the criterion are on the same field" do

        let(:selection) do
          query.nor({ first: [ 1, 2 ] }, { first: [ 3, 4 ] })
        end

        it "appends both $nor expressions" do
          expect(selection.selector).to eq({
            "$nor" => [
              { "first" => [ 1, 2 ] },
              { "first" => [ 3, 4 ] }
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end
    end

    context "when chaining the criterion" do

      context "when the criterion are fnor different fields" do

        let(:selection) do
          query.nor(first: [ 1, 2 ]).nor(second: [ 3, 4 ])
        end

        it "adds the $nor selectors" do
          expect(selection.selector).to eq({
            "$nor" => [
              { "first" => [ 1, 2 ] },
              { "second" => [ 3, 4 ] }
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end

      context "when the criterion are on the same field" do

        let(:selection) do
          query.nor(first: [ 1, 2 ]).nor(first: [ 3, 4 ])
        end

        it "appends both $nor expressions" do
          expect(selection.selector).to eq({
            "$nor" => [
              { "first" => [ 1, 2 ] },
              { "first" => [ 3, 4 ] }
            ]
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when argument is a Criteria' do
      let(:tested_method) { :nor }
      let(:expected_operator) { '$nor' }

      it_behaves_like 'logical combination'
    end
  end

  describe "#not" do

    context "when provided no criterion" do

      let(:selection) do
        query.not
      end

      it "does not add any criterion" do
        expect(selection.selector).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it "returns a non cloned query" do
        expect(selection).to equal(query)
      end

      context "when the following criteria is a query method" do

        let(:selection) do
          query.not.all(field: [ 1, 2 ])
        end

        it "negates the all selection" do
          expect(selection.selector).to eq(
            { "field" => { "$not" => { "$all" => [ 1, 2 ] }}}
          )
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end

        it "removes the negation on the clone" do
          expect(selection).to_not be_negating
        end
      end

      context "when the following criteria is a gt method" do

        let(:selection) do
          query.not.gt(age: 50)
        end

        it "negates the gt selection" do
          expect(selection.selector).to eq(
            { "age" => { "$not" => { "$gt" => 50 }}}
          )
        end

        it "returns a coned query" do
          expect(selection).to_not eq(query)
        end

        it "removes the negation on the clone" do
          expect(selection).to_not be_negating
        end
      end

      context "when the following criteria is a where" do

        let(:selection) do
          query.not.where(field: 1, :other.in => [ 1, 2 ])
        end

        it "negates the selection with an operator" do
          expect(selection.selector).to eq(
            { "field" => { "$ne" => 1 }, "other" => { "$not" => { "$in" => [ 1, 2 ] }}}
          )
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end

        it "removes the negation on the clone" do
          expect(selection).to_not be_negating
        end
      end

      context "when the following criteria is a where with a regexp" do

        let(:selection) do
          query.not.where(field: 1, other: /test/)
        end

        it "negates the selection with an operator" do
          expect(selection.selector).to eq(
            { "field" => { "$ne" => 1 }, "other" => { "$not" => /test/ } }
          )
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end

        it "removes the negation on the clone" do
          expect(selection).to_not be_negating
        end

      end
    end

    context "when provided nil" do

      let(:selection) do
        query.not(nil)
      end

      it "does not add any criterion" do
        expect(selection.selector).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it "returns a cloned query" do
        expect(selection).to_not equal(query)
      end
    end

    context "when provided a single criterion" do

      let(:selection) do
        query.not(field: /test/)
      end

      it "adds the $not selector" do
        expect(selection.selector).to eq({
          "field" => { "$not" => /test/ }
        })
      end

      it "returns a cloned query" do
        expect(selection).to_not equal(query)
      end
    end

    context "when provided multiple criterion" do

      context "when the criterion are for different fields" do

        let(:selection) do
          query.not(first: /1/, second: /2/)
        end

        it "adds the $not selectors" do
          expect(selection.selector).to eq({
            "first" => { "$not" => /1/ },
            "second" => { "$not" => /2/ }
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end
    end

    context "when chaining the criterion" do

      context "when the criterion are for different fields" do

        let(:selection) do
          query.not(first: /1/).not(second: /2/)
        end

        it "adds the $not selectors" do
          expect(selection.selector).to eq({
            "first" => { "$not" => /1/ },
            "second" => { "$not" => /2/ }
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end

      context "when the criterion are on the same field" do

        let(:selection) do
          query.not(first: /1/).not(first: /2/)
        end

        it "overwrites the first $not selector" do
          expect(selection.selector).to eq({
            "first" =>  { "$not" => /2/ }
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end

      context "when the criterion are a double negative" do

        let(:selection) do
          query.not.where(:first.not => /1/)
        end

        it "does not double the $not selector" do
          expect(selection.selector).to eq({
            "first" =>  { "$not" => /1/ }
          })
        end

        it "returns a cloned query" do
          expect(selection).to_not equal(query)
        end
      end
    end
  end
end
