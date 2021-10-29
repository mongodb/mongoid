# frozen_string_literal: true

require "spec_helper"
require_relative './selectable_shared_examples'

describe Mongoid::Criteria::Queryable::Selectable do

  let(:query) do
    Mongoid::Query.new("id" => "_id")
  end

  describe "#where" do

    let(:query_method) { :where }

    context "when provided no criterion" do

      let(:selection) do
        query.where
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

    it_behaves_like 'requires a non-nil argument'

    context "when provided a string" do

      let(:selection) do
        query.where("this.value = 10")
      end

      it "adds the $where criterion" do
        expect(selection.selector).to eq({ "$where" => "this.value = 10" })
      end

      it "returns a cloned query" do
        expect(selection).to_not equal(query)
      end

      context 'when multiple calls with string argument are made' do

        let(:selection) do
          query.where("this.value = 10").where('foo.bar')
        end

        it 'combines conditions' do
          expect(selection.selector).to eq(
            "$where" => "this.value = 10", '$and' => [{'$where' => 'foo.bar'}],
          )
        end
      end

      context 'when called with string argument and with hash argument' do

        let(:selection) do
          query.where("this.value = 10").where(foo: 'bar')
        end

        it 'combines conditions' do
          expect(selection.selector).to eq(
            "$where" => "this.value = 10", 'foo' => 'bar',
          )
        end
      end

      context 'when called with hash argument and with string argument' do

        let(:selection) do
          query.where(foo: 'bar').where("this.value = 10")
        end

        it 'combines conditions' do
          expect(selection.selector).to eq(
            'foo' => 'bar', "$where" => "this.value = 10",
          )
        end
      end

      context 'when called with two hash arguments' do
        context 'when arguments use operators' do
          shared_examples 'combines conditions' do

            it 'combines conditions' do
              expect(selection.selector).to eq(
                'foo' => {'$in' => [1]},
                '$and' => ['foo' => {'$in' => [2]}],
              )
            end
          end

          context 'string operators' do

            let(:selection) do
              query.where(foo: {'$in' => [1]}).where(foo: {'$in' => [2]})
            end

            include_examples 'combines conditions'
          end

          context 'symbol operators' do

            let(:selection) do
              query.where(foo: {:$in => [1]}).where(foo: {:$in => [2]})
            end

            include_examples 'combines conditions'
          end

          context 'string and symbol operators' do

            let(:selection) do
              query.where(foo: {'$in' => [1]}).where(foo: {:$in => [2]})
            end

            include_examples 'combines conditions'
          end

          context 'symbol and string operators' do

            let(:selection) do
              query.where(foo: {:$in => [1]}).where(foo: {'$in' => [2]})
            end

            include_examples 'combines conditions'
          end
        end
      end
    end

    context "when provided a single criterion" do

      context "when the value needs no evolution" do

        let(:selection) do
          query.where(name: "Syd")
        end

        it "adds the criterion to the selection" do
          expect(selection.selector).to eq({ "name" => "Syd" })
        end
      end

      context "when the value must be evolved" do

        before(:all) do
          class Document
            def id
              13
            end
            def self.evolve(object)
              object.id
            end
          end
        end

        after(:all) do
          Object.send(:remove_const, :Document)
        end

        context "when the key needs evolution" do

          let(:query) do
            Mongoid::Query.new({ "user" => "user_id" })
          end

          let(:document) do
            Document.new
          end

          let(:selection) do
            query.where(user: document)
          end

          it "alters the key and value" do
            expect(selection.selector).to eq({ "user_id" => document.id })
          end
        end

        context 'when the field is a String and the value is a BSON::Regexp::Raw' do

          let(:raw_regexp) do
            BSON::Regexp::Raw.new('^Em')
          end

          let(:selection) do
            Login.where(_id: raw_regexp)
          end

          it 'does not convert the bson raw regexp object to a String' do
            expect(selection.selector).to eq({ "_id" => raw_regexp })
          end
        end
      end
    end

    context "when provided complex criterion" do

      context "when performing an $all" do

        context "when performing a single query" do

          let(:selection) do
            query.where(:field.all => [ 1, 2 ])
          end

          it "adds the $all criterion" do
            expect(selection.selector).to eq({ "field" => { "$all" => [ 1, 2 ] }})
          end

          it "returns a cloned query" do
            expect(selection).to_not eq(query)
          end
        end
      end

      context "when performing an $elemMatch" do

        context "when the value is not complex" do

          let(:selection) do
            query.where(:field.elem_match => { key: 1 })
          end

          it "adds the $elemMatch criterion" do
            expect(selection.selector).to eq(
              { "field" => { "$elemMatch" => { 'key' => 1 } }}
            )
          end

          it "returns a cloned query" do
            expect(selection).to_not eq(query)
          end
        end

        context "when the value is complex" do

          let(:selection) do
            query.where(:field.elem_match => { :key.gt => 1 })
          end

          it "adds the $elemMatch criterion" do
            expect(selection.selector).to eq(
              { "field" => { "$elemMatch" => { "key" => { "$gt" => 1 }}}}
            )
          end

          it "returns a cloned query" do
            expect(selection).to_not eq(query)
          end
        end
      end

      context "when performing an $exists" do

        context "when providing boolean values" do

          let(:selection) do
            query.where(:field.exists => true)
          end

          it "adds the $exists criterion" do
            expect(selection.selector).to eq(
              { "field" => { "$exists" => true }}
            )
          end

          it "returns a cloned query" do
            expect(selection).to_not eq(query)
          end
        end

        context "when providing string values" do

          let(:selection) do
            query.where(:field.exists => "t")
          end

          it "adds the $exists criterion" do
            expect(selection.selector).to eq(
              { "field" => { "$exists" => true }}
            )
          end

          it "returns a cloned query" do
            expect(selection).to_not eq(query)
          end
        end
      end

      context "when performing a $gt" do

        let(:selection) do
          query.where(:field.gt => 10)
        end

        it "adds the $gt criterion" do
          expect(selection.selector).to eq(
            { "field" => { "$gt" => 10 }}
          )
        end

        it "returns a cloned query" do
          expect(selection).to_not eq(query)
        end
      end

      context "when performing a $gte" do

        let(:selection) do
          query.where(:field.gte => 10)
        end

        it "adds the $gte criterion" do
          expect(selection.selector).to eq(
            { "field" => { "$gte" => 10 }}
          )
        end

        it "returns a cloned query" do
          expect(selection).to_not eq(query)
        end
      end

      context "when performing an $in" do

        let(:selection) do
          query.where(:field.in => [ 1, 2 ])
        end

        it "adds the $in criterion" do
          expect(selection.selector).to eq({ "field" => { "$in" => [ 1, 2 ] }})
        end

        it "returns a cloned query" do
          expect(selection).to_not eq(query)
        end
      end

      context "when performing a $lt" do

        let(:selection) do
          query.where(:field.lt => 10)
        end

        it "adds the $lt criterion" do
          expect(selection.selector).to eq(
            { "field" => { "$lt" => 10 }}
          )
        end

        it "returns a cloned query" do
          expect(selection).to_not eq(query)
        end
      end

      context "when performing a $lte" do

        let(:selection) do
          query.where(:field.lte => 10)
        end

        it "adds the $lte criterion" do
          expect(selection.selector).to eq(
            { "field" => { "$lte" => 10 }}
          )
        end

        it "returns a cloned query" do
          expect(selection).to_not eq(query)
        end
      end

      context "when performing a $mod" do

        let(:selection) do
          query.where(:field.mod => [ 10, 1 ])
        end

        it "adds the $lte criterion" do
          expect(selection.selector).to eq(
            { "field" => { "$mod" => [ 10, 1 ]}}
          )
        end

        it "returns a cloned query" do
          expect(selection).to_not eq(query)
        end
      end

      context "when performing a $ne" do

        let(:selection) do
          query.where(:field.ne => 10)
        end

        it "adds the $ne criterion" do
          expect(selection.selector).to eq(
            { "field" => { "$ne" => 10 }}
          )
        end

        it "returns a cloned query" do
          expect(selection).to_not eq(query)
        end
      end

      context "when performing a $near" do

        let(:selection) do
          query.where(:field.near => [ 1, 1 ])
        end

        it "adds the $near criterion" do
          expect(selection.selector).to eq(
            { "field" => { "$near" => [ 1, 1 ] }}
          )
        end

        it "returns a cloned query" do
          expect(selection).to_not eq(query)
        end
      end

      context "when performing a $nearSphere" do

        let(:selection) do
          query.where(:field.near_sphere => [ 1, 1 ])
        end

        it "adds the $nearSphere criterion" do
          expect(selection.selector).to eq(
            { "field" => { "$nearSphere" => [ 1, 1 ] }}
          )
        end

        it "returns a cloned query" do
          expect(selection).to_not eq(query)
        end
      end

      context "when performing a $nin" do

        let(:selection) do
          query.where(:field.nin => [ 1, 2 ])
        end

        it "adds the $nin criterion" do
          expect(selection.selector).to eq({ "field" => { "$nin" => [ 1, 2 ] }})
        end

        it "returns a cloned query" do
          expect(selection).to_not eq(query)
        end
      end

      context "when performing a $not" do

        let(:selection) do
          query.where(:field.not => /test/)
        end

        it "adds the $not criterion" do
          expect(selection.selector).to eq({ "field" => { "$not" => /test/ }})
        end

        it "returns a cloned query" do
          expect(selection).to_not eq(query)
        end
      end

      context "when performing a $size" do

        context "when providing an integer" do

          let(:selection) do
            query.where(:field.with_size => 10)
          end

          it "adds the $size criterion" do
            expect(selection.selector).to eq(
              { "field" => { "$size" => 10 }}
            )
          end

          it "returns a cloned query" do
            expect(selection).to_not eq(query)
          end
        end

        context "when providing a string" do

          let(:selection) do
            query.where(:field.with_size => "10")
          end

          it "adds the $size criterion" do
            expect(selection.selector).to eq(
              { "field" => { "$size" => 10 }}
            )
          end

          it "returns a cloned query" do
            expect(selection).to_not eq(query)
          end
        end
      end

      context "when performing a $type" do

        let(:selection) do
          query.where(:field.with_type => 10)
        end

        it "adds the $type criterion" do
          expect(selection.selector).to eq(
            { "field" => { "$type" => 10 }}
          )
        end

        it "returns a cloned query" do
          expect(selection).to_not eq(query)
        end
      end
    end

    context 'when using an MQL logical operator manually' do
      let(:base_query) do
        query.where(test: 1)
      end

      let(:selection) do
        base_query.where(mql_operator => ['hello' => 'world'])
      end

      shared_examples_for 'adds conditions to existing query' do
        it 'adds conditions to existing query' do
          selection.selector.should == {
            'test' => 1,
            mql_operator => ['hello' => 'world'],
          }
        end
      end

      shared_examples_for 'adds conditions to existing query with an extra $and' do
        it 'adds conditions to existing query' do
          selection.selector.should == {
            'test' => 1,
            mql_operator => ['hello' => 'world'],
          }
        end
      end

      context '$or' do
        let(:mql_operator) { '$or' }

        it_behaves_like 'adds conditions to existing query with an extra $and'
      end

      context '$nor' do
        let(:mql_operator) { '$nor' }

        it_behaves_like 'adds conditions to existing query with an extra $and'
      end

      context '$not' do
        let(:mql_operator) { '$not' }

        it_behaves_like 'adds conditions to existing query'
      end

      context '$and' do
        let(:mql_operator) { '$and' }

        it_behaves_like 'adds conditions to existing query'
      end
    end
  end
end
