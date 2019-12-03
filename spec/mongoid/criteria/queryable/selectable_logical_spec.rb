# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Criteria::Queryable::Selectable do

  let(:query) do
    Mongoid::Query.new("id" => "_id")
  end

  shared_examples_for 'returns a cloned query' do

    it "returns a cloned query" do
      expect(selection).to_not equal(query)
    end
  end

  shared_examples_for 'a non-combining logical operation' do

    context 'when there is a single predicate' do
      let(:query) do
        Mongoid::Query.new.send(tested_method, hello: 'world')
      end

      it 'adds the predicate' do
        expect(query.selector).to eq(expected_operator => [{'hello' => 'world'}])
      end
    end

    context 'when the single predicate is wrapped in an array' do
      let(:query) do
        Mongoid::Query.new.send(tested_method, [{hello: 'world'}])
      end

      it 'adds the predicate' do
        expect(query.selector).to eq(expected_operator => [{'hello' => 'world'}])
      end
    end

    context 'when argument is a Criteria' do
      let(:query) do
        Mongoid::Query.new.where(hello: 'world')
      end

      let(:other) do
        Mongoid::Query.new.where(foo: 'bar')
      end

      let(:result) { query.send(tested_method, other) }

      it 'combines' do
        # This is used for $or / $nor, the two conditions should remain
        # as separate hashes
        expect(result.selector).to eq(expected_operator => [{'hello' => 'world'}, {'foo' => 'bar'}])
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
        expect(result.selector).to eq(expected_operator => [
          {'hello' => 'world'},
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

      it_behaves_like 'returns a cloned query'
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

      it_behaves_like 'returns a cloned query'
    end

    context "when provided a single criterion" do

      shared_examples_for 'adds the conditions to top level' do

        it "adds the conditions to top level" do
          expect(selection.selector).to eq({
            "field" => [ 1, 2 ]
          })
        end

        it_behaves_like 'returns a cloned query'
      end

      let(:selection) do
        query.and(field: [ 1, 2 ])
      end

      it_behaves_like 'adds the conditions to top level'

      context 'when the criterion is wrapped in an array' do
        let(:selection) do
          query.and([{field: [ 1, 2 ] }])
        end

        it_behaves_like 'adds the conditions to top level'
      end

      context 'when the criterion is wrapped in a deep array with nil elements' do
        let(:selection) do
          query.and([[[{field: [ 1, 2 ] }]], [nil]])
        end

        it_behaves_like 'adds the conditions to top level'
      end
    end

    context "when provided a single criterion that is handled via Key" do

      shared_examples_for 'adds the conditions to top level' do

        it "adds the conditions to top level" do
          expect(selection.selector).to eq({
            "field" => {'$gt' => 3 },
          })
        end

        it_behaves_like 'returns a cloned query'
      end

      let(:selection) do
        query.and(:field.gt => 3)
      end

      it_behaves_like 'adds the conditions to top level'

      context 'when the criterion is wrapped in an array' do
        let(:selection) do
          query.and([{ :field.gt => 3 }])
        end

        it_behaves_like 'adds the conditions to top level'
      end

      context 'when the criterion is wrapped in a deep array with nil elements' do
        let(:selection) do
          query.and([[[{ :field.gt => 3 }]], [nil]])
        end

        it_behaves_like 'adds the conditions to top level'
      end
    end

    context "when provided a nested criterion" do

      let(:selection) do
        query.and(:test.elem_match => { :field.in => [ 1, 2 ] })
      end

      it "builds the correct selector" do
        expect(selection.selector).to eq({
          "test" => { "$elemMatch" => { "field" => { "$in" => [ 1, 2 ] }}}
        })
      end

      it_behaves_like 'returns a cloned query'
    end

    context "when provided multiple criteria" do

      context "when the criteria is already included" do

        let(:selection) do
          query.and({ first: [ 1, 2 ] }).and({ first: [ 1, 2 ] })
        end

        it "adds all conditions" do
          expect(selection.selector).to eq({
            'first' => [1, 2],
            "$and" => [
              { "first" => [ 1, 2 ] }
            ]
          })
        end

        it_behaves_like 'returns a cloned query'
      end

      context "when the new criterion is for different fields" do

        let(:selection) do
          query.and({ first: [ 1, 2 ] }, { second: [ 3, 4 ] })
        end

        it "adds all conditions to top level" do
          expect(selection.selector).to eq({
            "first" => [ 1, 2 ],
            "second" => [ 3, 4 ],
          })
        end

        it_behaves_like 'returns a cloned query'
      end

      context "when the new criterion is for the same field" do

        let(:selection) do
          query.and({ first: [ 1, 2 ] }, { first: [ 3, 4 ] })
        end

        it "combines via $and operator" do
          expect(selection.selector).to eq({
            "first" => [ 1, 2 ],
            "$and" => [
              { "first" => [ 3, 4 ] }
            ]
          })
        end

        it_behaves_like 'returns a cloned query'
      end
    end

    context "when chaining the criteria" do

      context "when the criteria are for different fields" do

        let(:selection) do
          query.and(first: [ 1, 2 ]).and(second: [ 3, 4 ])
        end

        it "adds the conditions to top level" do
          expect(selection.selector).to eq({
            "first" => [ 1, 2 ],
            "second" => [ 3, 4 ],
          })
        end

        it_behaves_like 'returns a cloned query'
      end

      context "when the criteria are on the same field" do

        let(:selection) do
          query.and(first: [ 1, 2 ]).and(first: [ 3, 4 ])
        end

        it "combines via $and operator" do
          expect(selection.selector).to eq({
            "first" => [ 1, 2 ],
            "$and" => [
              { "first" => [ 3, 4 ] }
            ]
          })
        end

        it_behaves_like 'returns a cloned query'
      end
    end

    context 'when argument is a Criteria' do
      let(:query) do
        Mongoid::Query.new.where(hello: 'world')
      end

      let(:result) { query.and(other) }

      context 'different fields' do

        let(:other) do
          Mongoid::Query.new.where(foo: 'bar')
        end

        it 'combines both fields at top level' do
          expect(result.selector).to eq('hello' => 'world', 'foo' => 'bar')
        end
      end

      context 'same field' do

        let(:other) do
          Mongoid::Query.new.where(hello: /bar/)
        end

        it 'combines fields with $and' do
          expect(result.selector).to eq('hello' => 'world', '$and' => [{'hello' => /bar/}])
        end
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

      let(:result) { query.and(other1, other2, other3) }

      it 'combines' do
        expect(result.selector).to eq('hello' => 'world',
          'foo' => 'bar',
          'bar' => 42,
          'a' => 2,
        )
      end
    end

    context 'when Key instances are used and types involved have serializers' do
      let(:time) { Time.now }

      let(:query) do
        Band.all.and(:created_at.gt => time)
      end

      let(:expected) do
        {'created_at' => {'$gt' => time.utc}}
      end

      it 'combines and evolves' do
        expect(query.selector).to eq(expected)
      end
    end

    describe 'query shape' do
      shared_examples_for 'adds most recent criterion as $and' do
        let(:selector) { scope.selector }

        it 'adds most recent criterion as $and' do
          expect(selector).to eq('foo' => 1, '$and' => [{'foo' => 2}])
        end
      end

      context 'and/and' do
        let(:scope) do
          Band.and(foo: 1).and(foo: 2)
        end

        it_behaves_like 'adds most recent criterion as $and'
      end

      context 'and/and' do
        let(:scope) do
          Band.and(foo: 1).and(foo: 2)
        end

        it_behaves_like 'adds most recent criterion as $and'
      end

      context 'and/where' do
        let(:scope) do
          Band.and(foo: 1).where(foo: 2)
        end

        it_behaves_like 'adds most recent criterion as $and'
      end

      context 'where/and' do
        let(:scope) do
          Band.where(foo: 1).and(foo: 2)
        end

        it_behaves_like 'adds most recent criterion as $and'
      end

      context 'where/where' do
        let(:scope) do
          Band.where(foo: 1).where(foo: 2)
        end

        it_behaves_like 'adds most recent criterion as $and'
      end
    end
  end

  describe "#or" do

    let(:tested_method) { :or }
    let(:expected_operator) { '$or' }

    it_behaves_like 'a non-combining logical operation'

    context "when provided no arguments" do

      let(:selection) do
        query.or
      end

      it_behaves_like 'returns a cloned query'

      it "does not add any criteria" do
        expect(selection.selector).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end
    end

    context "when provided nil" do

      let(:selection) do
        query.or(nil)
      end

      it_behaves_like 'returns a cloned query'

      it "does not add any criteria" do
        expect(selection.selector).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end
    end

    context "when provided a single criterion" do

      let(:selection) do
        query.or(field: [ 1, 2 ])
      end

      it_behaves_like 'returns a cloned query'

      it "adds the $or selector" do
        expect(selection.selector).to eq({
          "$or" => [{ "field" => [ 1, 2 ] }]
        })
      end

      context 'when the criterion is wrapped in array' do

        let(:selection) do
          query.or([{ field: [ 1, 2 ] }])
        end

        it_behaves_like 'returns a cloned query'

        it "adds the $or selector" do
          expect(selection.selector).to eq({
            "$or" => [{ "field" => [ 1, 2 ] }]
          })
        end

        context 'when the array has nil as one of the elements' do

          let(:selection) do
            query.or([{ field: [ 1, 2 ] }, nil])
          end

          it_behaves_like 'returns a cloned query'

          it "adds the $or selector ignoring the nil element" do
            expect(selection.selector).to eq({
              "$or" => [{ "field" => [ 1, 2 ] }]
            })
          end
        end
      end

      context 'when query already has a condition on another field' do

        let(:selection) do
          query.where(foo: 'bar').or(field: [ 1, 2 ])
        end

        it 'moves original conditions under $or' do
          expect(selection.selector).to eq({
            "$or" => [{'foo' => 'bar'}, { "field" => [ 1, 2 ] }]
          })
        end
      end

      context 'when query already has an $or condition and another condition' do

        let(:selection) do
          query.or(field: [ 1, 2 ]).where(foo: 'bar').or(test: 1)
        end

        it 'unions existing conditions' do
          expect(selection.selector).to eq(
            '$or' => [
              {
                "$or" => [{ "field" => [ 1, 2 ] }],
                'foo' => 'bar',
              },
              {'test' => 1},
            ]
          )
        end
      end
    end

    context "when provided multiple criteria" do

      context "when the criteria are for different fields" do

        let(:selection) do
          query.or({ first: [ 1, 2 ] }, { second: [ 3, 4 ] })
        end

        it_behaves_like 'returns a cloned query'

        it "adds the $or selector" do
          expect(selection.selector).to eq({
            "$or" => [
              { "first" => [ 1, 2 ] },
              { "second" => [ 3, 4 ] }
            ]
          })
        end
      end

      context "when the criteria uses a Key instance" do

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

        it_behaves_like 'returns a cloned query'
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

        it_behaves_like 'returns a cloned query'
      end

      context "when a criterion is wrapped in an array" do

        let(:selection) do
          query.or([{ first: [ 1, 2 ] }, { :second.gt => 3 }])
        end

        it_behaves_like 'returns a cloned query'

        it "adds the $or selector" do
          expect(selection.selector).to eq({
            "$or" => [
              { "first" => [ 1, 2 ] },
              { "second" => { "$gt" => 3 }}
            ]
          })
        end
      end

      context "when the criteria are on the same field" do

        let(:selection) do
          query.or({ first: [ 1, 2 ] }, { first: [ 3, 4 ] })
        end

        it_behaves_like 'returns a cloned query'

        it "appends both $or expressions" do
          expect(selection.selector).to eq({
            "$or" => [
              { "first" => [ 1, 2 ] },
              { "first" => [ 3, 4 ] }
            ]
          })
        end
      end
    end

    context "when chaining the criterion" do

      context "when the criterion are for different fields" do

        let(:selection) do
          query.or(first: [ 1, 2 ]).or(second: [ 3, 4 ])
        end

        it_behaves_like 'returns a cloned query'

        it "adds the $or selectors" do
          expect(selection.selector).to eq({
            "$or" => [
              { "first" => [ 1, 2 ] },
              { "second" => [ 3, 4 ] }
            ]
          })
        end
      end

      context "when the criterion are on the same field" do

        let(:selection) do
          query.or(first: [ 1, 2 ]).or(first: [ 3, 4 ])
        end

        it_behaves_like 'returns a cloned query'

        it "appends both $or expressions" do
          expect(selection.selector).to eq({
            "$or" => [
              { "first" => [ 1, 2 ] },
              { "first" => [ 3, 4 ] }
            ]
          })
        end
      end
    end
  end

  describe "#nor" do

    let(:tested_method) { :nor }
    let(:expected_operator) { '$nor' }

    it_behaves_like 'a non-combining logical operation'

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

      it_behaves_like 'returns a cloned query'
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

      it_behaves_like 'returns a cloned query'
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

      it_behaves_like 'returns a cloned query'
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

        it_behaves_like 'returns a cloned query'
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

        it_behaves_like 'returns a cloned query'
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

        it_behaves_like 'returns a cloned query'
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

        it_behaves_like 'returns a cloned query'
      end
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

      it "returns a cloned query" do
        expect(selection).not_to equal(query)
      end

      it 'does not mutate receiver' do
        expect(query.negating).to be nil

        selection
        expect(query.negating).to be nil
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

        it_behaves_like 'returns a cloned query'

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

        it_behaves_like 'returns a cloned query'

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

        it_behaves_like 'returns a cloned query'

        it "removes the negation on the clone" do
          expect(selection).to_not be_negating
        end
      end

      context 'when the following criteria uses string were form' do

        let(:selection) do
          query.not.where('hello world')
        end

        it "negates the selection with an operator" do
          expect(selection.selector).to eq(
            '$and' => [{'$nor' => [{'$where' => 'hello world'}]}]
          )
        end

        it_behaves_like 'returns a cloned query'

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

      it_behaves_like 'returns a cloned query'
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

      it_behaves_like 'returns a cloned query'
    end

    context "when negating a field in the original selector" do
      let(:query) do
        Mongoid::Query.new("id" => "_id").where(field: 'foo')
      end

      let(:selection) do
        query.not(field: 'bar')
      end

      it "combines the conditions" do
        expect(selection.selector).to eq({
          "field" => 'foo',
          '$and' => [{'$nor' => [{ "field" => 'bar' }]}],
        })
      end

      it_behaves_like 'returns a cloned query'
    end

    context "when provided multiple criteria" do

      context "when the criteria are for different fields" do

        let(:selection) do
          query.not(first: /1/, second: /2/)
        end

        it "adds the $not selectors" do
          expect(selection.selector).to eq({
            "first" => { "$not" => /1/ },
            "second" => { "$not" => /2/ }
          })
        end

        it_behaves_like 'returns a cloned query'
      end

      context "when the criteria are given in separate arguments" do

        let(:selection) do
          query.not({first: /1/}, {second: /2/})
        end

        it "adds the $not selectors" do
          expect(selection.selector).to eq({
            "first" => { "$not" => /1/ },
            "second" => { "$not" => /2/ }
          })
        end

        it_behaves_like 'returns a cloned query'
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

        it_behaves_like 'returns a cloned query'
      end

      context "when the criterion are on the same field" do

        let(:selection) do
          query.not(first: /1/).not(first: /2/)
        end

        it "combines conditions" do
          expect(selection.selector).to eq(
            "first" =>  { "$not" => /1/ },
            '$and' => [{'$nor' => [{'first' => /2/}]}],
          )
        end

        it_behaves_like 'returns a cloned query'
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

        it_behaves_like 'returns a cloned query'
      end
    end

    context 'when argument is a Criteria' do
      let(:query) do
        Mongoid::Query.new.where(hello: 'world')
      end

      let(:other) do
        Mongoid::Query.new.where(foo: 'bar')
      end

      let(:result) { query.not(other) }

      it 'combines' do
        expect(result.selector).to eq('hello' => 'world', 'foo' => {'$ne' => 'bar'})
      end
    end

    context 'when argument is a simple Criteria with multiple fields' do
      let(:query) do
        Mongoid::Query.new.where(hello: 'world')
      end

      let(:other) do
        Mongoid::Query.new.where(a: 1, b: 2)
      end

      let(:result) { query.not(other) }

      it 'combines fields into top level criteria' do
        expect(result.selector).to eq('hello' => 'world',
          'a' => {'$ne' => 1}, 'b' => {'$ne' => 2})
      end
    end

    context 'when argument is a complex Criteria' do
      let(:query) do
        Mongoid::Query.new.where(hello: 'world')
      end

      let(:other) do
        Mongoid::Query.new.where('$nor' => [{a: 1, b: 2}])
      end

      let(:result) { query.not(other) }

      it 'combines with $and of $nor' do
        expect(result.selector).to eq('hello' => 'world', '$and' => [{'$nor' => [{
          '$nor' => [{'a' => 1, 'b' => 2}]}]}])
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

      let(:result) { query.not(other1, other2, other3) }

      it 'combines' do
        expect(result.selector).to eq('hello' => 'world',
          'foo' => {'$ne' => 'bar'},
          'bar' => {'$ne' => 42},
          'a' => {'$ne' => 2},
        )
      end
    end
  end
end
