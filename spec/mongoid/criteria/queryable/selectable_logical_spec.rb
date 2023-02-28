# frozen_string_literal: true

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

  # Hoisting means the operator can be elided, for example
  # Foo.and(a: 1) produces simply {'a' => 1}.
  shared_examples_for 'a hoisting logical operation' do

    let(:query) do
      Mongoid::Query.new
    end

    context "when provided a single criterion" do

      shared_examples_for 'adds the conditions to top level' do

        it "adds the conditions to top level" do
          expect(selection.selector).to eq(
            "field" => [ 1, 2 ]
          )
        end

        it_behaves_like 'returns a cloned query'
      end

      let(:selection) do
        query.send(tested_method, field: [ 1, 2 ])
      end

      it_behaves_like 'adds the conditions to top level'

      context 'when the criterion is wrapped in an array' do
        let(:selection) do
          query.send(tested_method, [{field: [ 1, 2 ] }])
        end

        it_behaves_like 'adds the conditions to top level'
      end

      context 'when the criterion is wrapped in a deep array with nil elements' do
        let(:selection) do
          query.send(tested_method, [[[{field: [ 1, 2 ] }]], [nil]])
        end

        it_behaves_like 'adds the conditions to top level'
      end
    end

    context 'when argument is a Criteria' do
      let(:base) do
        query.where(hello: 'world')
      end

      let(:other) do
        query.where(foo: 'bar')
      end

      let(:result) { base.send(tested_method, other) }

      it 'combines' do
        expect(result.selector).to eq(
          'hello' => 'world',
          'foo' => 'bar',
        )
      end
    end

    context "when provided a single criterion that is handled via Key" do

      shared_examples_for 'adds the conditions to top level' do

        it "adds the conditions to top level" do
          expect(selection.selector).to eq({
            "field" => {'$gt' => 3},
          })
        end

        it_behaves_like 'returns a cloned query'
      end

      let(:selection) do
        query.send(tested_method, :field.gt => 3)
      end

      it_behaves_like 'adds the conditions to top level'

      context 'when the criterion is wrapped in an array' do
        let(:selection) do
          query.send(tested_method, [{ :field.gt => 3 }])
        end

        it_behaves_like 'adds the conditions to top level'
      end

      context 'when the criterion is wrapped in a deep array with nil elements' do
        let(:selection) do
          query.send(tested_method, [[[{ :field.gt => 3 }]], [nil]])
        end

        it_behaves_like 'adds the conditions to top level'
      end

      context 'when the criterion is a time' do
        let(:selection) do
          query.send(tested_method, :field.gte => Time.new(2020, 1, 1))
        end

        it 'adds the conditions' do
          expect(selection.selector).to eq({
            "field" => {'$gte' => Time.new(2020, 1, 1)},
          })
        end

        it 'keeps argument type' do
          selection.selector['field']['$gte'].should be_a(Time)
        end
      end

      context 'when the criterion is a datetime' do
        let(:selection) do
          query.send(tested_method, :field.gte => DateTime.new(2020, 1, 1))
        end

        it 'adds the conditions' do
          expect(selection.selector).to eq({
            "field" => {'$gte' => Time.utc(2020, 1, 1)},
          })
        end

        it 'converts argument to a time' do
          selection.selector['field']['$gte'].should be_a(Time)
        end
      end

      context 'when the criterion is a date' do
        let(:selection) do
          query.send(tested_method, :field.gte => Date.new(2020, 1, 1))
        end

        it 'adds the conditions' do
          expect(selection.selector).to eq({
            "field" => {'$gte' => Time.utc(2020, 1, 1)},
          })
        end

        it 'converts argument to a time' do
          selection.selector['field']['$gte'].should be_a(Time)
        end
      end
    end

    context "when provided a nested criterion" do

      let(:selection) do
        query.send(tested_method, :test.elem_match => { :field.in => [ 1, 2 ] })
      end

      it "builds the correct selector" do
        expect(selection.selector).to eq({
          "test" => { "$elemMatch" => { "field" => { "$in" => [ 1, 2 ] }}}
        })
      end

      it_behaves_like 'returns a cloned query'
    end

    context "when chaining the criteria" do

      context "when the criteria are for different fields" do

        let(:selection) do
          query.and(first: [ 1, 2 ]).send(tested_method, second: [ 3, 4 ])
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
          query.and(first: [ 1, 2 ]).send(tested_method, first: [ 3, 4 ])
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
  end

  # Non-hoisting means the operator is always present, for example
  # Foo.or(a: 1) produces {'$or' => [{'a' => 1}]}.
  shared_examples_for 'a non-hoisting logical operation' do

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

    let(:tested_method) { :and }
    let(:expected_operator) { '$and' }

    it_behaves_like 'a hoisting logical operation'

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

    context "when provided multiple criteria" do

      context "when the criterion is already included" do

        context 'simple criterion' do
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

        context 'Key criterion' do
          let(:selection) do
            query.and({ first: [ 1, 2 ] }).and(:first.gt => 3)
          end

          it "adds all conditions" do
            expect(selection.selector).to eq({
              'first' => [1, 2],
              "$and" => [
                { "first" => {'$gt' => 3} }
              ]
            })
          end

          it_behaves_like 'returns a cloned query'
        end

        context 'Key criterion when existing criterion is an operator' do
          let(:selection) do
            query.and(:first.lt => 5).and(:first.gt => 3)
          end

          it "adds all conditions" do
            expect(selection.selector).to eq({
              'first' => {'$lt' => 5, '$gt' => 3},
            })
          end

          it_behaves_like 'returns a cloned query'
        end
      end

      context "when the new criteria are for different fields" do

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

      context "when the new criteria are for the same field" do

        context 'when criteria are simple' do
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

        context 'when criteria use operators' do
          shared_examples 'behave correctly' do
            let(:selection) do
              query.and(
                { field: {first_operator => [ 1, 2 ] }},
                { field: {second_operator => [ 3, 4 ] }},
              )
            end

            it "combines via $and operator and stringifies all keys" do
              expect(selection.selector).to eq({
                "field" => {'$in' => [ 1, 2 ]},
                "$and" => [
                  { "field" => {'$in' => [ 3, 4 ] }}
                ]
              })
            end
          end

          [
            ['$in', '$in'],
            [:$in, '$in'],
            ['$in', :$in],
            [:$in, :$in],
          ].each do |first_operator, second_operator|
            context "when first operator is #{first_operator.inspect} and second operator is #{second_operator.inspect}" do
              let(:first_operator) { first_operator }
              let(:second_operator) { second_operator }

              include_examples 'behave correctly'
            end
          end
        end

        context 'when criteria are handled via Key' do
          shared_examples_for 'adds the conditions to top level' do

            it "adds the conditions to top level" do
              expect(selection.selector).to eq({
                "field" => {'$gt' => 3, '$lt' => 5},
              })
            end

            it_behaves_like 'returns a cloned query'
          end

          context 'criteria are provided in the same hash' do
            let(:selection) do
              query.send(tested_method, :field.gt => 3, :field.lt => 5)
            end

            it_behaves_like 'adds the conditions to top level'
          end

          context 'criteria are provided in separate hashes' do
            let(:selection) do
              query.send(tested_method, {:field.gt => 3}, {:field.lt => 5})
            end

            it_behaves_like 'adds the conditions to top level'
          end

          context 'when the criterion is wrapped in an array' do
            let(:selection) do
              query.send(tested_method, [:field.gt => 3], [:field.lt => 5])
            end

            it_behaves_like 'adds the conditions to top level'
          end
        end

        context 'when criteria are simple and handled via Key' do
          shared_examples_for 'combines conditions with $and' do

            it "combines conditions with $and" do
              expect(selection.selector).to eq({
                "field" => 3,
                '$and' => ['field' => {'$lt' => 5}],
              })
            end

            it_behaves_like 'returns a cloned query'
          end

          shared_examples_for 'combines conditions with $eq' do

            it "combines conditions with $eq" do
              expect(selection.selector).to eq({
                "field" => {'$eq' => 3, '$lt' => 5},
              })
            end

            it_behaves_like 'returns a cloned query'
          end

          shared_examples_for 'combines conditions with $regex' do

            it "combines conditions with $regex" do
              expect(selection.selector).to eq({
                "field" => {'$regex' => /t/, '$lt' => 5},
              })
            end

            it_behaves_like 'returns a cloned query'
          end

          context 'criteria are provided in the same hash' do
            context 'non-regexp argument' do
              let(:selection) do
                query.send(tested_method, :field => 3, :field.lt => 5)
              end

              it_behaves_like 'combines conditions with $eq'
            end

            context 'regexp argument' do
              let(:selection) do
                query.send(tested_method, :field => /t/, :field.lt => 5)
              end

              it_behaves_like 'combines conditions with $regex'
            end
          end

          context 'criteria are provided in separate hashes' do
            let(:selection) do
              query.send(tested_method, {:field => 3}, {:field.lt => 5})
            end

            it_behaves_like 'combines conditions with $and'
          end

          context 'when the criterion is wrapped in an array' do
            let(:selection) do
              query.send(tested_method, [:field => 3], [:field.lt => 5])
            end

            it_behaves_like 'combines conditions with $and'
          end
        end

        context 'when criteria are handled via Key and simple' do
          shared_examples_for 'combines conditions with $and' do

            it "combines conditions with $and" do
              expect(selection.selector).to eq({
                "field" => {'$gt' => 3},
                '$and' => ['field' => 5],
              })
            end

            it_behaves_like 'returns a cloned query'
          end

          shared_examples_for 'combines conditions with $eq' do

            it "combines conditions with $eq" do
              expect(selection.selector).to eq({
                "field" => {'$gt' => 3, '$eq' => 5},
              })
            end

            it_behaves_like 'returns a cloned query'
          end

          shared_examples_for 'combines conditions with $regex' do

            it "combines conditions with $regex" do
              expect(selection.selector).to eq({
                "field" => {'$gt' => 3, '$regex' => /t/},
              })
            end

            it_behaves_like 'returns a cloned query'
          end

          context 'criteria are provided in the same hash' do
            context 'non-regexp argument' do
              let(:selection) do
                query.send(tested_method, :field.gt => 3, :field => 5)
              end

              it_behaves_like 'combines conditions with $eq'
            end

            context 'regexp argument' do
              let(:selection) do
                query.send(tested_method, :field.gt => 3, :field => /t/)
              end

              it_behaves_like 'combines conditions with $regex'
            end
          end

          context 'criteria are provided in separate hashes' do
            let(:selection) do
              query.send(tested_method, {:field.gt => 3}, {:field => 5})
            end

            it_behaves_like 'combines conditions with $and'
          end

          context 'when the criterion is wrapped in an array' do
            let(:selection) do
              query.send(tested_method, [:field.gt => 3], [:field => 5])
            end

            it_behaves_like 'combines conditions with $and'
          end
        end
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

    context 'when conditions already exist in criteria' do
      let(:base_selection) do
        query.where(foo: 'bar')
      end

      context 'when hash conditions are given' do
        let(:selection) do
          base_selection.and(hello: 'world')
        end

        it 'adds new conditions to top level' do
          selection.selector.should == {
            'foo' => 'bar',
            'hello' => 'world',
          }
        end
      end

      context 'when criteria conditions are given' do
        let(:selection) do
          base_selection.and(query.where(hello: 'world'))
        end

        it 'adds new conditions to top level' do
          selection.selector.should == {
            'foo' => 'bar',
            'hello' => 'world',
          }
        end
      end

      context 'when complex criteria conditions are given' do
        let(:selection) do
          base_selection.and(query.or([one: 'one'], [two: 'two']))
        end

        it 'adds new conditions to top level' do
          selection.selector.should == {
            'foo' => 'bar',
            '$or' => [
              {'one' => 'one'},
              {'two' => 'two'},
            ],
          }
        end
      end
    end
  end

  shared_examples '$or/$nor' do

    it_behaves_like 'a non-hoisting logical operation'

    context "when provided no arguments" do

      let(:selection) do
        query.send(tested_method)
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
        query.send(tested_method, nil)
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
        query.send(tested_method, field: [ 1, 2 ])
      end

      it_behaves_like 'returns a cloned query'

      it "adds the $or/$nor selector" do
        expect(selection.selector).to eq({
          expected_operator => [{ "field" => [ 1, 2 ] }]
        })
      end

      context 'when the criterion is wrapped in array' do

        let(:selection) do
          query.send(tested_method, [{ field: [ 1, 2 ] }])
        end

        it_behaves_like 'returns a cloned query'

        it "adds the $or/$nor selector" do
          expect(selection.selector).to eq({
            expected_operator => [{ "field" => [ 1, 2 ] }]
          })
        end

        context 'when the array has nil as one of the elements' do

          let(:selection) do
            query.send(tested_method, [{ field: [ 1, 2 ] }, nil])
          end

          it_behaves_like 'returns a cloned query'

          it "adds the $or/$nor selector ignoring the nil element" do
            expect(selection.selector).to eq({
              expected_operator => [{ "field" => [ 1, 2 ] }]
            })
          end
        end
      end

      context 'when query already has a condition on another field' do

        let(:selection) do
          query.where(foo: 'bar').send(tested_method, field: [ 1, 2 ])
        end

        it 'moves original conditions under $or/$nor' do
          expect(selection.selector).to eq({
            expected_operator => [{'foo' => 'bar'}, { "field" => [ 1, 2 ] }]
          })
        end
      end

      context 'when query already has an $or/$nor condition and another condition' do

        let(:selection) do
          query.send(tested_method, field: [ 1, 2 ]).where(foo: 'bar').send(tested_method, test: 1)
        end

        it 'unions existing conditions' do
          expect(selection.selector).to eq(
            expected_operator => [
              {
                expected_operator => [{ "field" => [ 1, 2 ] }],
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
          query.send(tested_method, { first: [ 1, 2 ] }, { second: [ 3, 4 ] })
        end

        it_behaves_like 'returns a cloned query'

        it "adds the $or/$nor selector" do
          expect(selection.selector).to eq({
            expected_operator => [
              { "first" => [ 1, 2 ] },
              { "second" => [ 3, 4 ] }
            ]
          })
        end
      end

      context "when the criteria uses a Key instance" do

        let(:selection) do
          query.send(tested_method, { first: [ 1, 2 ] }, { :second.gt => 3 })
        end

        it "adds the $or/$nor selector" do
          expect(selection.selector).to eq({
            expected_operator => [
              { "first" => [ 1, 2 ] },
              { "second" => { "$gt" => 3 }}
            ]
          })
        end

        it_behaves_like 'returns a cloned query'

        context 'when the criterion is a time' do
          let(:selection) do
            query.send(tested_method, :field.gte => Time.new(2020, 1, 1))
          end

          it 'adds the conditions' do
            expect(selection.selector).to eq(expected_operator => [
              "field" => {'$gte' => Time.new(2020, 1, 1)},
            ])
          end

          it 'keeps the type' do
            selection.selector[expected_operator].first['field']['$gte'].should be_a(Time)
          end
        end

        context 'when the criterion is a datetime' do
          let(:selection) do
            query.send(tested_method, :field.gte => DateTime.new(2020, 1, 1))
          end

          it 'adds the conditions' do
            expect(selection.selector).to eq(expected_operator => [
              "field" => {'$gte' => Time.utc(2020, 1, 1)},
            ])
          end

          it 'converts argument to a time' do
            selection.selector[expected_operator].first['field']['$gte'].should be_a(Time)
          end
        end

        context 'when the criterion is a date' do
          let(:selection) do
            query.send(tested_method, :field.gte => Date.new(2020, 1, 1))
          end

          it 'adds the conditions' do
            expect(selection.selector).to eq(expected_operator => [
              "field" => {'$gte' => Time.utc(2020, 1, 1)},
            ])
          end

          it 'converts argument to a time' do
            selection.selector[expected_operator].first['field']['$gte'].should be_a(Time)
          end
        end
      end

      context "when a criterion has an aliased field" do

        let(:selection) do
          query.send(tested_method, { id: 1 })
        end

        it "adds the $or/$nor selector and aliases the field" do
          expect(selection.selector).to eq({
            expected_operator => [ { "_id" => 1 } ]
          })
        end

        it_behaves_like 'returns a cloned query'
      end

      context "when a criterion is wrapped in an array" do

        let(:selection) do
          query.send(tested_method, [{ first: [ 1, 2 ] }, { :second.gt => 3 }])
        end

        it_behaves_like 'returns a cloned query'

        it "adds the $or/$nor selector" do
          expect(selection.selector).to eq({
            expected_operator => [
              { "first" => [ 1, 2 ] },
              { "second" => { "$gt" => 3 }}
            ]
          })
        end
      end

      context "when the criteria are on the same field" do

        context 'simple criteria' do
          let(:selection) do
            query.send(tested_method, { first: [ 1, 2 ] }, { first: [ 3, 4 ] })
          end

          it_behaves_like 'returns a cloned query'

          it "appends both $or/$nor expressions" do
            expect(selection.selector).to eq({
              expected_operator => [
                { "first" => [ 1, 2 ] },
                { "first" => [ 3, 4 ] }
              ]
            })
          end
        end

        context 'Key criteria as one argument' do
          let(:selection) do
            query.send(tested_method, :first.gt => 3, :first.lt => 5)
          end

          it_behaves_like 'returns a cloned query'

          it "adds all criteria" do
            expect(selection.selector).to eq({
              expected_operator => [
                { "first" => {'$gt' => 3, '$lt' => 5} },
              ]
            })
          end
        end

        context 'Key criteria as multiple arguments' do
          let(:selection) do
            query.send(tested_method, {:first.gt => 3}, {:first.lt => 5})
          end

          it_behaves_like 'returns a cloned query'

          it "adds all criteria" do
            expect(selection.selector).to eq({
              expected_operator => [
                { "first" => {'$gt' => 3} },
                { "first" => {'$lt' => 5} },
              ]
            })
          end
        end
      end
    end

    context "when chaining the criterion" do

      context "when the criterion are for different fields" do

        let(:selection) do
          query.send(tested_method, first: [ 1, 2 ]).send(tested_method, second: [ 3, 4 ])
        end

        it_behaves_like 'returns a cloned query'

        it "adds the $or/$nor selectors" do
          expect(selection.selector).to eq({
            expected_operator => [
              { "first" => [ 1, 2 ] },
              { "second" => [ 3, 4 ] }
            ]
          })
        end
      end

      context "when the criterion are on the same field" do

        let(:selection) do
          query.send(tested_method, first: [ 1, 2 ]).send(tested_method, first: [ 3, 4 ])
        end

        it_behaves_like 'returns a cloned query'

        it "appends both $or/$nor expressions" do
          expect(selection.selector).to eq({
            expected_operator => [
              { "first" => [ 1, 2 ] },
              { "first" => [ 3, 4 ] }
            ]
          })
        end
      end
    end

    context 'when giving multiple conditions in one call on the same key with symbol operator' do

      context 'non-regexp argument' do
        let(:selection) do
          query.send(tested_method, field: 1, :field.gt => 0)
        end

        it 'combines conditions with $eq' do
          selection.selector.should == {
            expected_operator => [
              'field' => {'$eq' => 1, '$gt' => 0},
            ]
          }
        end
      end

      context 'regexp argument' do
        let(:selection) do
          query.send(tested_method, field: /t/, :field.gt => 0)
        end

        it 'combines conditions with $regex' do
          selection.selector.should == {
            expected_operator => [
              'field' => {'$regex' => /t/, '$gt' => 0},
            ]
          }
        end
      end

    end
  end

  describe "#or" do

    let(:tested_method) { :or }
    let(:expected_operator) { '$or' }

    it_behaves_like '$or/$nor'
  end

  describe "#nor" do

    let(:tested_method) { :nor }
    let(:expected_operator) { '$nor' }

    it_behaves_like '$or/$nor'
  end

  describe "#any_of" do

    let(:tested_method) { :any_of }
    let(:expected_operator) { '$or' }

    it_behaves_like 'a hoisting logical operation'

    # When multiple arguments are given to any_of, it behaves differently
    # from and.
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
        expect(result.selector).to eq(
          'hello' => 'world',
          expected_operator => [
            {'foo' => 'bar'},
            {'bar' => 42},
            {'a' => 2},
          ],
        )
      end
    end

    context "when provided no arguments" do

      let(:selection) do
        query.any_of
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
        query.any_of(nil)
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
        query.any_of(field: [ 1, 2 ])
      end

      it_behaves_like 'returns a cloned query'

      it "adds the $or selector" do
        expect(selection.selector).to eq(
          "field" => [ 1, 2 ],
        )
      end

      context 'when the criterion is wrapped in array' do

        let(:selection) do
          query.any_of([{ field: [ 1, 2 ] }])
        end

        it_behaves_like 'returns a cloned query'

        it "adds the condition" do
          expect(selection.selector).to eq(
            "field" => [ 1, 2 ],
          )
        end

        context 'when the array has nil as one of the elements' do

          let(:selection) do
            query.any_of([{ field: [ 1, 2 ] }, nil])
          end

          it_behaves_like 'returns a cloned query'

          it "adds the $or selector ignoring the nil element" do
            expect(selection.selector).to eq(
              "field" => [ 1, 2 ],
            )
          end
        end
      end

      context 'when query already has a condition on another field' do

        context 'when there is one argument' do

          let(:selection) do
            query.where(foo: 'bar').any_of(field: [ 1, 2 ])
          end

          it 'adds the new condition' do
            expect(selection.selector).to eq(
              'foo' => 'bar',
              'field' => [1, 2],
            )
          end
        end

        context 'when there are multiple arguments' do

          let(:selection) do
            query.where(foo: 'bar').any_of({field: [ 1, 2 ]}, {hello: 'world'})
          end

          it 'adds the new condition' do
            expect(selection.selector).to eq(
              'foo' => 'bar',
              '$or' => [
                {'field' => [1, 2]},
                {'hello' => 'world'},
              ],
            )
          end
        end
      end

      context 'when query already has an $or condition and another condition' do

        let(:selection) do
          query.or(field: [ 1, 2 ]).where(foo: 'bar').any_of(test: 1)
        end

        it 'adds the new condition' do
          expect(selection.selector).to eq(
            '$or' => [{'field' => [1, 2]}],
            'foo' => 'bar',
            'test' => 1,
          )
        end
      end

      context 'when any_of has multiple arguments' do

        let(:selection) do
          query.or(field: [ 1, 2 ]).where(foo: 'bar').any_of({a: 1}, {b: 2})
        end

        it 'adds the new condition to top level' do
          expect(selection.selector).to eq(
            '$or' => [{'field' => [1, 2]}],
            'foo' => 'bar',
            '$and' => [{'$or' => [{'a' => 1}, {'b' => 2}]}],
          )
        end

        context 'when query already has a top-level $and' do
          let(:selection) do
            query.or(field: [ 1, 2 ]).where('$and' => [foo: 'bar']).any_of({a: 1}, {b: 2})
          end

          it 'adds the new condition to top level $and' do
            expect(selection.selector).to eq(
              '$or' => [{'field' => [1, 2]}],
              '$and' => [{'foo' => 'bar'}, {'$or' => [{'a' => 1}, {'b' => 2}]}],
            )
          end
        end
      end
    end

    context "when provided multiple criteria" do

      context "when the criteria are for different fields" do

        let(:selection) do
          query.any_of({ first: [ 1, 2 ] }, { second: [ 3, 4 ] })
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
          query.any_of({ first: [ 1, 2 ] }, { :second.gt => 3 })
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

      context 'when criteria are simple and handled via Key' do
        shared_examples_for 'adds conditions with $or' do

          it "adds conditions with $or" do
            expect(selection.selector).to eq({
              '$or' => [
                {'field' => 3},
                {'field' => {'$lt' => 5}},
              ],
            })
          end

          it_behaves_like 'returns a cloned query'
        end

        shared_examples_for 'combines conditions with $eq' do

          it "combines conditions with $eq" do
            expect(selection.selector).to eq({
              'field' => {
                '$eq' => 3,
                '$lt' => 5,
              },
            })
          end

          it_behaves_like 'returns a cloned query'
        end

        shared_examples_for 'combines conditions with $regex' do

          it "combines conditions with $regex" do
            expect(selection.selector).to eq({
              'field' => {
                '$regex' => /t/,
                '$lt' => 5,
              },
            })
          end

          it_behaves_like 'returns a cloned query'
        end

        context 'criteria are provided in the same hash' do
          context 'non-regexp argument' do
            let(:selection) do
              query.send(tested_method, :field => 3, :field.lt => 5)
            end

            it_behaves_like 'combines conditions with $eq'
          end

          context 'regexp argument' do
            let(:selection) do
              query.send(tested_method, :field => /t/, :field.lt => 5)
            end

            it_behaves_like 'combines conditions with $regex'
          end
        end

        context 'criteria are provided in separate hashes' do
          let(:selection) do
            query.send(tested_method, {:field => 3}, {:field.lt => 5})
          end

          it_behaves_like 'adds conditions with $or'
        end

        context 'when the criterion is wrapped in an array' do
          let(:selection) do
            query.send(tested_method, [:field => 3], [:field.lt => 5])
          end

          it_behaves_like 'adds conditions with $or'
        end
      end

      context 'when criteria are handled via Key and simple' do
        shared_examples_for 'adds conditions with $or' do

          it "adds conditions with $or" do
            expect(selection.selector).to eq({
              '$or' => [
                {'field' => {'$gt' => 3}},
                {'field' => 5},
              ],
            })
          end

          it_behaves_like 'returns a cloned query'
        end

        shared_examples_for 'combines conditions with $eq' do

          it "combines conditions with $eq" do
            expect(selection.selector).to eq(
              'field' => {'$gt' => 3, '$eq' => 5},
            )
          end

          it_behaves_like 'returns a cloned query'
        end

        shared_examples_for 'combines conditions with $regex' do

          it "combines conditions with $regex" do
            expect(selection.selector).to eq(
              'field' => {'$gt' => 3, '$regex' => /t/},
            )
          end

          it_behaves_like 'returns a cloned query'
        end

        context 'criteria are provided in the same hash' do
          context 'non-regexp argument' do
            let(:selection) do
              query.send(tested_method, :field.gt => 3, :field => 5)
            end

            it_behaves_like 'combines conditions with $eq'
          end

          context 'regexp argument' do
            let(:selection) do
              query.send(tested_method, :field.gt => 3, :field => /t/)
            end

            it_behaves_like 'combines conditions with $regex'
          end
        end

        context 'criteria are provided in separate hashes' do
          let(:selection) do
            query.send(tested_method, {:field.gt => 3}, {:field => 5})
          end

          it_behaves_like 'adds conditions with $or'
        end

        context 'when the criterion is wrapped in an array' do
          let(:selection) do
            query.send(tested_method, [:field.gt => 3], [:field => 5])
          end

          it_behaves_like 'adds conditions with $or'
        end
      end

      context "when a criterion has an aliased field" do

        let(:selection) do
          query.any_of({ id: 1 })
        end

        it "adds the $or selector and aliases the field" do
          expect(selection.selector).to eq(
            "_id" => 1,
          )
        end

        it_behaves_like 'returns a cloned query'
      end

      context "when a criterion is wrapped in an array" do

        let(:selection) do
          query.any_of([{ first: [ 1, 2 ] }, { :second.gt => 3 }])
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
          query.any_of({ first: [ 1, 2 ] }, { first: [ 3, 4 ] })
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

    context "when chaining the criteria" do

      context "when the criteria are for different fields" do

        let(:selection) do
          query.any_of(first: [ 1, 2 ]).any_of(second: [ 3, 4 ])
        end

        it_behaves_like 'returns a cloned query'

        it "adds the conditions separately" do
          expect(selection.selector).to eq(
            "first" => [ 1, 2 ],
            "second" => [ 3, 4 ],
          )
        end
      end

      context "when the criteria are on the same field" do

        let(:selection) do
          query.any_of(first: [ 1, 2 ]).any_of(first: [ 3, 4 ])
        end

        it_behaves_like 'returns a cloned query'

        it "adds the conditions separately" do
          expect(selection.selector).to eq(
            "first" => [ 1, 2 ],
            '$and' => [{"first" => [ 3, 4 ]}],
          )
        end
      end
    end

    context 'when using multiple criteria and symbol operators' do
      context 'when using fields that meaningfully evolve values' do

        let(:query) do
          Dictionary.any_of({a: 1}, :published.gt => Date.new(2020, 2, 3))
        end

        it 'generates the expected query' do
          query.selector.should == {'$or' => [
            {'a' => 1},
            # Date instance is converted to a Time instance in local time,
            # because we are querying on a Time field and dates are interpreted
            # in local time when assigning to Time fields
            {'published' => {'$gt' => Time.local(2020, 2, 3)}},
          ]}
        end
      end

      context 'when using fields that do not meaningfully evolve values' do

        let(:query) do
          Dictionary.any_of({a: 1}, :submitted_on.gt => Date.new(2020, 2, 3))
        end

        it 'generates the expected query' do
          query.selector.should == {'$or' => [
            {'a' => 1},
            # Date instance is converted to a Time instance in UTC,
            # because we are querying on a Date field and dates are interpreted
            # in UTC when persisted as dates by Mongoid
            {'submitted_on' => {'$gt' => Time.utc(2020, 2, 3)}},
          ]}
        end
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

      shared_examples_for 'negates the next condition' do
        let(:selection) do
          query.not.send(query_method, field: [ 1, 2 ])
        end

        it "negates the next condition" do
          expect(selection.selector).to eq(
            { "field" => { "$not" => { operator => [ 1, 2 ] }}}
          )
        end

        it_behaves_like 'returns a cloned query'

        it "removes the negation on the clone" do
          expect(selection).to_not be_negating
        end
      end

      context "when the next condition is #all" do
        let(:query_method) { :all }
        let(:operator) { '$all' }

        it_behaves_like 'negates the next condition'
      end

      context "when the next condition is #in" do
        let(:query_method) { :in }
        let(:operator) { '$in' }

        it_behaves_like 'negates the next condition'
      end

      context "when the next condition is #nin" do
        let(:query_method) { :nin }
        let(:operator) { '$nin' }

        it_behaves_like 'negates the next condition'
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

        it_behaves_like 'returns a cloned query'

        it "removes the negation on the clone" do
          expect(selection).to_not be_negating
        end
      end

      context "when the criteria uses Key" do

        let(:selection) do
          query.not(:age.gt => 50)
        end

        it "negates the gt selection" do
          expect(selection.selector).to eq(
            '$and' => ['$nor' => ['age' => {'$gt' => 50}]]
          )
        end

        it_behaves_like 'returns a cloned query'

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

    context 'when giving multiple conditions in one call on the same key with symbol operator' do

      context 'non-regexp argument' do
        let(:selection) do
          query.not(field: 1, :field.gt => 0)
        end

        it 'combines conditions with $eq' do
          selection.selector.should == {
            '$and' => ['$nor' => [
              'field' => {'$eq' => 1, '$gt' => 0},
            ]]
          }
        end
      end

      context 'regexp argument' do
        let(:selection) do
          query.not(field: /t/, :field.gt => 0)
        end

        it 'combines conditions with $regex' do
          selection.selector.should == {
            '$and' => ['$nor' => [
              'field' => {'$regex' => /t/, '$gt' => 0},
            ]]
          }
        end
      end
    end

    # This test confirms that MONGOID-5097 has been repaired.
    context "when using exists on a field of type Time" do
      let(:criteria) do
        Dictionary.any_of({:published.exists => true}, published: nil)
      end

      it "doesn't raise an error" do
        expect do
          criteria
        end.to_not raise_error
      end

      it "generates the correct selector" do
        expect(criteria.selector).to eq({
          "$or" => [ {
            "published" => { "$exists" => true }
          }, {
            "published" => nil
          } ] } )
      end
    end
  end

  describe "#none_of" do
    context 'when argument is a mix of Criteria and hashes' do
      let(:query) { Mongoid::Query.new.where(hello: 'world') }
      let(:other1) { Mongoid::Query.new.where(foo: 'bar') }
      let(:other2) { { bar: 42 } }
      let(:other3) { Mongoid::Query.new.where(a: 2) }

      let(:result) { query.none_of(other1, other2, other3) }

      it 'combines' do
        expect(result.selector).to eq(
          'hello' => 'world',
          '$nor' => [
            {'foo' => 'bar'},
            {'bar' => 42},
            {'a' => 2},
          ],
        )
      end
    end

    context "when provided no arguments" do
      let(:selection) { query.none_of }

      it_behaves_like 'returns a cloned query'

      it "does not add any criteria" do
        expect(selection.selector).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end
    end

    context "when provided nil" do
      let(:selection) { query.none_of(nil) }

      it_behaves_like 'returns a cloned query'

      it "does not add any criteria" do
        expect(selection.selector).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end
    end

    context "when provided a single criterion" do
      let(:selection) { query.none_of(field: [ 1, 2 ]) }

      it_behaves_like 'returns a cloned query'

      it 'adds the $nor selector' do
        expect(selection.selector).to eq(
          '$nor' => [ { 'field' => [ 1, 2 ] } ],
        )
      end

      context 'when the criterion is wrapped in array' do
        let(:selection) { query.none_of([{ field: [ 1, 2 ] }]) }

        it_behaves_like 'returns a cloned query'

        it 'adds the condition' do
          expect(selection.selector).to eq(
            '$nor' => [ { 'field' => [ 1, 2 ] } ],
          )
        end

        context 'when the array has nil as one of the elements' do
          let(:selection) { query.none_of([{ field: [ 1, 2 ] }, nil]) }

          it_behaves_like 'returns a cloned query'

          it 'adds the $nor selector ignoring the nil element' do
            expect(selection.selector).to eq(
              '$nor' => [ { 'field' => [ 1, 2 ] } ],
            )
          end
        end
      end

      context 'when query already has a condition on another field' do
        context 'when there is one argument' do
          let(:selection) { query.where(foo: 'bar').none_of(field: [ 1, 2 ]) }

          it 'adds the new condition' do
            expect(selection.selector).to eq(
              'foo' => 'bar',
              '$nor' => [ { 'field' => [1, 2] } ],
            )
          end
        end

        context 'when there are multiple arguments' do
          let(:selection) do
            query.where(foo: 'bar').none_of({ field: [ 1, 2 ] }, { hello: 'world' })
          end

          it 'adds the new condition' do
            expect(selection.selector).to eq(
              'foo' => 'bar',
              '$nor' => [
                { 'field' => [1, 2] },
                { 'hello' => 'world' },
              ],
            )
          end
        end
      end

      context 'when query already has a $nor condition and another condition' do
        let(:selection) do
          query.nor(field: [ 1, 2 ]).where(foo: 'bar').none_of(test: 1)
        end

        it 'adds the new condition' do
          expect(selection.selector).to eq(
            '$nor' => [ { 'field' => [1, 2] } ],
            'foo' => 'bar',
            '$and' => [ { '$nor' => [ { 'test' => 1 } ] } ]
          )
        end
      end

      context 'when none_of has multiple arguments' do
        let(:selection) do
          query.nor(field: [ 1, 2 ]).where(foo: 'bar').none_of({a: 1}, {b: 2})
        end

        it 'adds the new condition to top level' do
          expect(selection.selector).to eq(
            'foo' => 'bar',
            '$nor' => [ { 'field' => [1, 2] } ],
            '$and' => [ { '$nor' => [ { 'a' => 1 }, { 'b' => 2 } ] } ]
          )
        end

        context 'when query already has a top-level $and' do
          let(:selection) do
            query.nor(field: [ 1, 2 ]).where('$and' => [foo: 'bar']).none_of({a: 1}, {b: 2})
          end

          it 'adds the new condition to top level $and' do
            expect(selection.selector).to eq(
              '$nor' => [ { 'field' => [1, 2] } ],
              '$and' => [
                { 'foo' => 'bar' },
                { '$nor' => [ { 'a' => 1 }, { 'b' => 2 } ] }
              ],
            )
          end
        end
      end
    end

    context "when provided multiple criteria" do
      context "when the criteria are for different fields" do
        let(:selection) do
          query.none_of({ first: [ 1, 2 ] }, { second: [ 3, 4 ] })
        end

        it_behaves_like 'returns a cloned query'

        it "adds the $nor selector" do
          expect(selection.selector).to eq({
            "$nor" => [
              { "first" => [ 1, 2 ] },
              { "second" => [ 3, 4 ] }
            ]
          })
        end
      end

      context "when the criteria uses a Key instance" do
        let(:selection) do
          query.none_of({ first: [ 1, 2 ] }, { :second.gt => 3 })
        end

        it "adds the $nor selector" do
          expect(selection.selector).to eq({
            "$nor" => [
              { "first" => [ 1, 2 ] },
              { "second" => { "$gt" => 3 }}
            ]
          })
        end

        it_behaves_like 'returns a cloned query'
      end

      context 'when criteria are simple and handled via Key' do
        shared_examples_for 'adds conditions with $nor' do
          it "adds conditions with $nor" do
            expect(selection.selector).to eq({
              '$nor' => [
                {'field' => 3},
                {'field' => {'$lt' => 5}},
              ],
            })
          end

          it_behaves_like 'returns a cloned query'
        end

        shared_examples_for 'combines conditions with $eq' do
          it "combines conditions with $eq" do
            expect(selection.selector).to eq({
              '$nor' => [ { 'field' => { '$eq' => 3, '$lt' => 5 } } ]
            })
          end

          it_behaves_like 'returns a cloned query'
        end

        shared_examples_for 'combines conditions with $regex' do
          it 'combines conditions with $regex' do
            expect(selection.selector).to eq({
              '$nor' => [ { 'field' => { '$regex' => /t/, '$lt' => 5 } } ]
            })
          end

          it_behaves_like 'returns a cloned query'
        end

        context 'criteria are provided in the same hash' do
          context 'non-regexp argument' do
            let(:selection) { query.none_of(:field => 3, :field.lt => 5) }
            it_behaves_like 'combines conditions with $eq'
          end

          context 'regexp argument' do
            let(:selection) { query.none_of(:field => /t/, :field.lt => 5) }
            it_behaves_like 'combines conditions with $regex'
          end
        end

        context 'criteria are provided in separate hashes' do
          let(:selection) { query.none_of({:field => 3}, {:field.lt => 5}) }
          it_behaves_like 'adds conditions with $nor'
        end

        context 'when the criterion is wrapped in an array' do
          let(:selection) { query.none_of([:field => 3], [:field.lt => 5]) }
          it_behaves_like 'adds conditions with $nor'
        end
      end

      context 'when criteria are handled via Key and simple' do
        shared_examples_for 'adds conditions with $nor' do
          it 'adds conditions with $nor' do
            expect(selection.selector).to eq({
              '$nor' => [
                { 'field' => { '$gt' => 3 } },
                { 'field' => 5 },
              ],
            })
          end

          it_behaves_like 'returns a cloned query'
        end

        shared_examples_for 'combines conditions with $eq' do
          it 'combines conditions with $eq' do
            expect(selection.selector).to eq(
              '$nor' => [ { 'field' => {'$gt' => 3, '$eq' => 5} } ],
            )
          end

          it_behaves_like 'returns a cloned query'
        end

        shared_examples_for 'combines conditions with $regex' do
          it 'combines conditions with $regex' do
            expect(selection.selector).to eq(
              '$nor' => [ { 'field' => {'$gt' => 3, '$regex' => /t/} } ],
            )
          end

          it_behaves_like 'returns a cloned query'
        end

        context 'criteria are provided in the same hash' do
          context 'non-regexp argument' do
            let(:selection) { query.none_of(:field.gt => 3, :field => 5) }
            it_behaves_like 'combines conditions with $eq'
          end

          context 'regexp argument' do
            let(:selection) { query.none_of(:field.gt => 3, :field => /t/) }
            it_behaves_like 'combines conditions with $regex'
          end
        end

        context 'criteria are provided in separate hashes' do
          let(:selection) { query.none_of({:field.gt => 3}, {:field => 5}) }
          it_behaves_like 'adds conditions with $nor'
        end

        context 'when the criterion is wrapped in an array' do
          let(:selection) { query.none_of([:field.gt => 3], [:field => 5]) }
          it_behaves_like 'adds conditions with $nor'
        end
      end

      context 'when a criterion has an aliased field' do
        let(:selection) { query.none_of({ id: 1 }) }
        
        it 'adds the $nor selector and aliases the field' do
          expect(selection.selector).to eq('$nor' => [{ '_id' => 1 }])
        end

        it_behaves_like 'returns a cloned query'
      end

      context 'when a criterion is wrapped in an array' do
        let(:selection) do
          query.none_of([{ first: [ 1, 2 ] }, { :second.gt => 3 }])
        end

        it_behaves_like 'returns a cloned query'

        it 'adds the $ nor selector' do
          expect(selection.selector).to eq({
            '$nor' => [
              { 'first' => [ 1, 2 ] },
              { 'second' => { '$gt' => 3 }}
            ]
          })
        end
      end

      context "when the criteria are on the same field" do
        let(:selection) do
          query.none_of({ first: [ 1, 2 ] }, { first: [ 3, 4 ] })
        end

        it_behaves_like 'returns a cloned query'

        it 'appends both $nor expressions' do
          expect(selection.selector).to eq({
            "$nor" => [
              { "first" => [ 1, 2 ] },
              { "first" => [ 3, 4 ] }
            ]
          })
        end
      end
    end

    context 'when chaining the criteria' do
      context 'when the criteria are for different fields' do
        let(:selection) do
          query.none_of(first: [ 1, 2 ]).none_of(second: [ 3, 4 ])
        end

        it_behaves_like 'returns a cloned query'

        it 'adds the conditions separately' do
          expect(selection.selector).to eq(
            '$nor' => [ { 'first' => [ 1, 2 ] } ],
            '$and' => [ { '$nor' => [ { 'second' => [ 3, 4 ] } ] } ],
          )
        end
      end

      context "when the criteria are on the same field" do
        let(:selection) do
          query.none_of(first: [ 1, 2 ]).none_of(first: [ 3, 4 ])
        end

        it_behaves_like 'returns a cloned query'

        it 'adds the conditions separately' do
          expect(selection.selector).to eq(
            '$nor' => [ { 'first' => [ 1, 2 ] } ],
            '$and' => [ { '$nor' => [ { 'first' => [ 3, 4 ] } ] } ]
          )
        end
      end
    end

    context 'when using multiple criteria and symbol operators' do
      context 'when using fields that meaningfully evolve values' do
        let(:query) do
          Dictionary.none_of({a: 1}, :published.gt => Date.new(2020, 2, 3))
        end

        it 'generates the expected query' do
          query.selector.should == {'$nor' => [
            {'a' => 1},
            # Date instance is converted to a Time instance in local time,
            # because we are querying on a Time field and dates are interpreted
            # in local time when assigning to Time fields
            {'published' => {'$gt' => Time.local(2020, 2, 3) } },
          ] }
        end
      end

      context 'when using fields that do not meaningfully evolve values' do
        let(:query) do
          Dictionary.none_of({a: 1}, :submitted_on.gt => Date.new(2020, 2, 3))
        end

        it 'generates the expected query' do
          query.selector.should == {'$nor' => [
            {'a' => 1},
            # Date instance is converted to a Time instance in UTC,
            # because we are querying on a Date field and dates are interpreted
            # in UTC when persisted as dates by Mongoid
            {'submitted_on' => {'$gt' => Time.utc(2020, 2, 3)}},
          ]}
        end
      end
    end
  end
end
