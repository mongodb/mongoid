# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Queryable::Selector do

  describe "merge!" do

    let(:selector) do
      described_class.new
    end

    context "when selector is nested" do

      before do
        selector[:field] = selection
        selector.merge!(other)
      end

      let(:selection) do
        { "$lt" => 50 }
      end

      context "when other contains same key with a hash" do

        let(:other) do
          { "field" => { "$gt" => 20 } }
        end

        it "deep merges" do
          expect(selector['field']).to eq({"$lt"=>50, "$gt" => 20})
        end
      end

      context "when other contains same key without hash" do

        let(:other) do
          { "field" => 10 }
        end

        it "merges" do
          expect(selector['field']).to eq(10)
        end
      end
    end

    context "when selector contains a $nin" do

      let(:initial) do
        { "$nin" => ["foo"] }
      end

      before do
        selector["field"] = initial
      end

      context "when merging in a new $nin" do

        let(:other) do
          { "field" => { "$nin" => ["bar"] } }
        end

        before do
          selector.merge!(other)
        end

        it "combines the two $nin queries into one" do
          expect(selector).to eq({
            "field" => { "$nin" => ["foo", "bar"] }
          })
        end
      end
    end

    context "when selector contains a $in" do

      let(:initial) do
        { "$in" => [1, 2] }
      end

      before do
        selector["field"] = initial
      end

      context "when merging in a new $in with an intersecting value" do

        let(:other) do
          { "field" => { "$in" => [1] } }
        end

        before do
          selector.merge!(other)
        end

        it "intersects the $in values" do
          expect(selector).to eq({
                                     "field" => { "$in" => [1] }
                                 })
        end
      end

      context "when merging in a new $in with no intersecting values" do

        let(:other) do
          { "field" => { "$in" => [3] } }
        end

        before do
          selector.merge!(other)
        end

        it "intersects the $in values" do
          expect(selector).to eq({
                                     "field" => { "$in" => [] }
                                 })
        end
      end
    end

    context "when selector is not nested" do

      before do
        selector[:field] = selection
        selector.merge!(other)
      end

      let(:selection) do
        50
      end

      let(:other) do
        { "field" => { "$gt" => 20 } }
      end

      it "merges" do
        expect(selector['field']).to eq({ "$gt" => 20 })
      end
    end

    context 'when an object does not support the | operator' do

      before do
        selector['start'] = selection
        selector.merge!(other)
      end

      let(:selection) do
        { '$lt' => Time.now }
      end

      let(:other) do
        { 'start' => selection, 'name' => 'test',  }
      end

      it "merges" do
        expect(selector['name']).to eq('test')
        expect(selector['start']).to eq(selection)
      end
    end

    context "when the selector contains an $or" do

      let(:initial) do
        [{ "value" => 1 }]
      end

      before do
        selector["$or"] = initial
      end

      context "when merging in a new $or" do

        let(:other) do
          [{ "value" => 2 }]
        end

        before do
          selector.merge!({ "$or" => other })
        end

        it "combines the two $or queries into one" do
          expect(selector).to eq({
            "$or" => [{ "value" => 1 }, { "value" => 2 }]
          })
        end
      end
    end

    context "when the selector contains an $and" do

      let(:initial) do
        [{ "value" => 1 }]
      end

      before do
        selector["$and"] = initial
      end

      context "when merging in a new $and" do

        let(:other) do
          [{ "value" => 2 }]
        end

        before do
          selector.merge!({ "$and" => other })
        end

        it "combines the two $and queries into one" do
          expect(selector).to eq({
            "$and" => [{ "value" => 1 }, { "value" => 2 }]
          })
        end
      end
    end

    context "when the selector contains a $nor" do

      let(:initial) do
        [{ "value" => 1 }]
      end

      before do
        selector["$nor"] = initial
      end

      context "when merging in a new $nor" do

        let(:other) do
          [{ "value" => 2 }]
        end

        before do
          selector.merge!({ "$nor" => other })
        end

        it "combines the two $nor queries into one" do
          expect(selector).to eq({
            "$nor" => initial + other
          })
        end
      end
    end
  end

  describe "#__deep_copy__" do

    let(:value) do
      [ 1, 2, 3 ]
    end

    let(:selection) do
      { "$in" => value }
    end

    let(:selector) do
      described_class.new
    end

    before do
      selector[:field] = selection
    end

    let(:cloned) do
      selector.__deep_copy__
    end

    it "returns an equal copy" do
      expect(cloned).to eq(selector)
    end

    it "performs a deep copy" do
      expect(cloned["field"]).to_not equal(selection)
    end

    it "clones n levels deep" do
      expect(cloned["field"]["$in"]).to_not equal(value)
    end
  end

  [ :store, :[]= ].each do |method|

    describe "##{method}" do

      context "when aliases are provided" do

        context "when the alias has no serializer" do

          let(:selector) do
            described_class.new({ "id" => "_id" })
          end

          before do
            selector.send(method, "id", 1)
          end

          it "stores the field in the selector by database name" do
            expect(selector["_id"]).to eq(1)
          end
        end

        context "when the alias has a serializer" do

          before(:all) do
            class Field
              def evolve(object)
                Integer.evolve(object)
              end

              def localized?
                false
              end
            end
          end

          after(:all) do
            Object.send(:remove_const, :Field)
          end

          let(:selector) do
            described_class.new(
              { "id" => "_id" }, { "_id" => Field.new }
            )
          end

          it "stores the serialized field in the selector by database name" do
            selector.send(method, "id", "1")
            expect(selector["_id"]).to eq(1)
          end

          it "stores the serialized field when selector is deeply nested" do
            selector.send(method, "$or", [{'$and' => [{'_id' => '5'}]}])
            expect(selector['$or'][0]['$and'][0]['_id']).to eq(5)
          end
        end
      end

      context "when no serializers are provided" do

        let(:selector) do
          described_class.new
        end

        context "when provided a standard object" do

          context "when the keys are strings" do

            it "does not serialize values" do
              expect(selector.send(method, "key", "5")).to eq("5")
            end
          end

          context "when the keys are symbols" do

            it "does not serialize values" do
              expect(selector.send(method, :key, "5")).to eq("5")
            end
          end
        end

        context "when provided a range" do

          before do
            selector.send(method, "key", 1..3)
          end

          it "serializes the range" do
            expect(selector["key"]).to eq({ "$gte" => 1, "$lte" => 3 })
          end
        end

        context "when providing an array" do

          let(:big_one) do
            BigDecimal("1.2321")
          end

          let(:big_two) do
            BigDecimal("4.2222")
          end

          let(:array) do
            [ big_one, big_two ]
          end

          before do
            selector.send(method, "key", array)
          end

          context 'when serializing bigdecimal to string' do
            config_override :map_big_decimal_to_decimal128, false

            it "serializes each element in the array" do
              expect(selector["key"]).to eq([ big_one.to_s, big_two.to_s ])
            end
          end

          context 'when serializing bigdecimal to decimal128' do
            config_override :map_big_decimal_to_decimal128, true

            it "serializes each element in the array" do
              expect(selector["key"]).to eq([ BSON::Decimal128.new(big_one), BSON::Decimal128.new(big_two)])
            end
          end
        end
      end

      context "when serializers are provided" do

        context "when the serializer is not localized" do

          before(:all) do
            class Field
              def evolve(object)
                Integer.evolve(object)
              end

              def localized?
                false
              end
            end
          end

          after(:all) do
            Object.send(:remove_const, :Field)
          end

          let(:selector) do
            described_class.new({}, { "key" => Field.new })
          end

          context "when the criterion is simple" do

            context "when the key is a string" do

              before do
                selector.send(method, "key", "5")
              end

              it "serializes the value" do
                expect(selector["key"]).to eq(5)
              end
            end

            context "when the key is a symbol" do

              before do
                selector.send(method, :key, "5")
              end

              it "serializes the value" do
                expect(selector["key"]).to eq(5)
              end
            end
          end

          context "when the criterion is complex" do

            context "when the field name is the key" do

              context "when the criterion is an array" do

                context "when the key is a string" do

                  before do
                    selector.send(method, "key", [ "1", "2" ])
                  end

                  it "serializes the value" do
                    expect(selector["key"]).to eq([ 1, 2 ])
                  end
                end

                context "when the key is a symbol" do

                  before do
                    selector.send(method, :key, [ "1", "2" ])
                  end

                  it "serializes the value" do
                    expect(selector["key"]).to eq([ 1, 2 ])
                  end
                end
              end

              context "when the criterion is a hash" do

                context "when the value is non enumerable" do

                  context "when the key is a string" do

                    before do
                      selector.send(method, "key", { "$gt" => "5" })
                    end

                    it "serializes the value" do
                      expect(selector["key"]).to eq({ "$gt" => 5 })
                    end
                  end

                  context "when the key is a symbol" do

                    before do
                      selector.send(method, :key, { "$gt" => "5" })
                    end

                    it "serializes the value" do
                      expect(selector["key"]).to eq({ "$gt" => 5 })
                    end
                  end
                end

                context "when the value is enumerable" do

                  context "when the key is a string" do

                    before do
                      selector.send(method, "key", { "$in" => [ "1", "2" ] })
                    end

                    it "serializes the value" do
                      expect(selector["key"]).to eq({ "$in" => [ 1, 2 ] })
                    end
                  end

                  context "when the key is a symbol" do

                    before do
                      selector.send(method, :key, { "$in" => [ "1", "2" ] })
                    end

                    it "serializes the value" do
                      expect(selector["key"]).to eq({ "$in" => [ 1, 2 ] })
                    end
                  end
                end

                [ "$and", "$or" ].each do |operator|

                  context "when the criterion is a #{operator}" do

                    context "when the individual criteria are simple" do

                      context "when the keys are strings" do

                        before do
                          selector.send(method, operator, [{ "key" => "1" }])
                        end

                        it "serializes the values" do
                          expect(selector[operator]).to eq([{ "key" => 1 }])
                        end
                      end

                      context "when the keys are symbols" do

                        before do
                          selector.send(method, operator, [{ key: "1" }])
                        end

                        it "serializes the values" do
                          expect(selector[operator]).to eq([{ "key" => 1 }])
                        end
                      end
                    end

                    context "when the individual criteria are complex" do

                      context "when the keys are strings" do

                        before do
                          selector.send(
                            method,
                            operator,
                            [{ "field" => "1" }, { "key" => { "$gt" => "2" }}]
                          )
                        end

                        it "serializes the values" do
                          expect(selector[operator]).to eq(
                            [{ "field" => "1" }, { "key" => { "$gt" => 2 }}]
                          )
                        end
                      end

                      context "when the keys are symbols" do

                        before do
                          selector.send(
                            method,
                            operator,
                            [{ field: "1" }, { key: { "$gt" => "2" }}]
                          )
                        end

                        it "serializes the values" do
                          expect(selector[operator]).to eq(
                            [{ "field" => "1" }, { "key" => { "$gt" => 2 }}]
                          )
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end

        context "when the serializer is localized" do
          with_default_i18n_configs

          before(:all) do
            class Field
              def evolve(object)
                Integer.evolve(object)
              end

              def localized?
                true
              end
            end
          end

          after(:all) do
            Object.send(:remove_const, :Field)
          end

          let(:selector) do
            described_class.new({}, { "key" => Field.new })
          end

          before do
            ::I18n.locale = :de
          end

          context "when the criterion is simple" do

            context "when the key is a string" do

              before do
                selector.send(method, "key", "5")
              end

              it "serializes the value" do
                expect(selector["key.de"]).to eq(5)
              end
            end

            context "when the key is a symbol" do

              before do
                selector.send(method, :key, "5")
              end

              it "serializes the value" do
                expect(selector["key.de"]).to eq(5)
              end
            end
          end

          context "when the criterion is complex" do

            context "when the field name is the key" do

              context "when the criterion is an array" do

                context "when the key is a string" do

                  before do
                    selector.send(method, "key", [ "1", "2" ])
                  end

                  it "serializes the value" do
                    expect(selector["key.de"]).to eq([ 1, 2 ])
                  end
                end

                context "when the key is a symbol" do

                  before do
                    selector.send(method, :key, [ "1", "2" ])
                  end

                  it "serializes the value" do
                    expect(selector["key.de"]).to eq([ 1, 2 ])
                  end
                end
              end

              context "when the criterion is a hash" do

                context "when the value is non enumerable" do

                  context "when the key is a string" do

                    let(:hash) do
                      { "$gt" => "5" }
                    end

                    before do
                      selector.send(method, "key", hash)
                    end

                    it "serializes the value" do
                      expect(selector["key.de"]).to eq({ "$gt" => 5 })
                    end

                    it "sets the same hash instance" do
                      expect(selector["key.de"]).to equal(hash)
                    end
                  end

                  context "when the key is a symbol" do

                    before do
                      selector.send(method, :key, { "$gt" => "5" })
                    end

                    it "serializes the value" do
                      expect(selector["key.de"]).to eq({ "$gt" => 5 })
                    end
                  end
                end

                context "when the value is enumerable" do

                  context "when the key is a string" do

                    before do
                      selector.send(method, "key", { "$in" => [ "1", "2" ] })
                    end

                    it "serializes the value" do
                      expect(selector["key.de"]).to eq({ "$in" => [ 1, 2 ] })
                    end
                  end

                  context "when the key is a symbol" do

                    before do
                      selector.send(method, :key, { "$in" => [ "1", "2" ] })
                    end

                    it "serializes the value" do
                      expect(selector["key.de"]).to eq({ "$in" => [ 1, 2 ] })
                    end
                  end
                end

                [ "$and", "$or" ].each do |operator|

                  context "when the criterion is a #{operator}" do

                    context "when the individual criteria are simple" do

                      context "when the keys are strings" do

                        before do
                          selector.send(method, operator, [{ "key" => "1" }])
                        end

                        it "serializes the values" do
                          expect(selector[operator]).to eq([{ "key.de" => 1 }])
                        end
                      end

                      context "when the keys are symbols" do

                        before do
                          selector.send(method, operator, [{ key: "1" }])
                        end

                        it "serializes the values" do
                          expect(selector[operator]).to eq([{ "key.de" => 1 }])
                        end
                      end
                    end

                    context "when the individual criteria are complex" do

                      context "when the keys are strings" do

                        before do
                          selector.send(
                            method,
                            operator,
                            [{ "field" => "1" }, { "key" => { "$gt" => "2" }}]
                          )
                        end

                        it "serializes the values" do
                          expect(selector[operator]).to eq(
                            [{ "field" => "1" }, { "key.de" => { "$gt" => 2 }}]
                          )
                        end
                      end

                      context "when the keys are symbols" do

                        before do
                          selector.send(
                            method,
                            operator,
                            [{ field: "1" }, { key: { "$gt" => "2" }}]
                          )
                        end

                        it "serializes the values" do
                          expect(selector[operator]).to eq(
                            [{ "field" => "1" }, { "key.de" => { "$gt" => 2 }}]
                          )
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  describe "#to_pipeline" do

    let(:selector) do
      described_class.new
    end

    context "when the selector is empty" do

      let(:pipeline) do
        selector.to_pipeline
      end

      it "returns an empty array" do
        expect(pipeline).to be_empty
      end
    end

    context "when the selector is not empty" do

      before do
        selector["name"] = "test"
      end

      let(:pipeline) do
        selector.to_pipeline
      end

      it "returns the selector in a $match entry" do
        expect(pipeline).to eq([{ "$match" => { "name" => "test" }}])
      end
    end
  end

  describe '#multi_selection?' do

    let(:selector) do
      described_class.new
    end

    context 'when key is $and' do
      it 'returns true' do
        expect(selector.send(:multi_selection?, '$and')).to be true
      end
    end

    context 'when key is $or' do
      it 'returns true' do
        expect(selector.send(:multi_selection?, '$or')).to be true
      end
    end

    context 'when key is $nor' do
      it 'returns true' do
        expect(selector.send(:multi_selection?, '$nor')).to be true
      end
    end

    context 'when key includes $or but is not $or' do
      it 'returns false' do
        expect(selector.send(:multi_selection?, '$ore')).to be false
      end
    end

    context 'when key is some other ey' do
      it 'returns false' do
        expect(selector.send(:multi_selection?, 'foo')).to be false
      end
    end
  end
end
