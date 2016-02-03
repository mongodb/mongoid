require "spec_helper"

describe Origin::Optional do

  let(:query) do
    Origin::Query.new
  end

  shared_examples_for "a cloning option" do

    it "returns a cloned query" do
      expect(selection).to_not equal(query)
    end
  end

  [ :asc, :ascending ].each do |method|

    describe "##{method}" do

      context "when using the official mongodb driver syntax" do

        context "when the query is aggregating" do

          let(:selection) do
            query.project(name: 1).send(method, :field_one, :field_two)
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: { "field_one" => 1, "field_two" => 1 }}
            )
          end

          it "adds the sort to the aggregation" do
            expect(selection.pipeline).to include(
              { "$sort" => { "field_one" => 1, "field_two" => 1 }}
            )
          end

          it "does not add multiple entries to the pipeline" do
            expect(selection.pipeline).to_not include(
              { "$sort" => { "field_one" => 1 }}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided symbols" do

          let(:selection) do
            query.send(method, :field_one, :field_two)
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: { "field_one" => 1, "field_two" => 1 }}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided an array of symbols" do

          let(:selection) do
            query.send(method, [ :field_one, :field_two ])
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: { "field_one" => 1, "field_two" => 1 }}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided strings" do

          let(:selection) do
            query.send(method, "field_one", "field_two")
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: { "field_one" => 1, "field_two" => 1 }}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided an array of strings" do

          let(:selection) do
            query.send(method, [ "field_one", "field_two" ])
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: { "field_one" => 1, "field_two" => 1 }}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided no options" do

          let(:selection) do
            query.send(method)
          end

          it "does not add any sorting criteria" do
            expect(selection.options).to be_empty
          end

          it "returns the query" do
            expect(selection).to eq(query)
          end

          it_behaves_like "a cloning option"
        end

        context "when provided nil" do

          let(:selection) do
            query.send(method, nil)
          end

          it "does not add any sorting criteria" do
            expect(selection.options).to be_empty
          end

          it "returns the query" do
            expect(selection).to eq(query)
          end

          it_behaves_like "a cloning option"
        end
      end

      context "when using the mongo-1.x driver syntax" do

        let(:query) do
          Origin::Query.new({}, {}, :mongo1x)
        end

        context "when provided symbols" do

          let(:selection) do
            query.send(method, :field_one, :field_two)
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: [[ :field_one, 1 ], [ :field_two, 1 ]]}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided an array of symbols" do

          let(:selection) do
            query.send(method, [ :field_one, :field_two ])
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: [[ :field_one, 1 ], [ :field_two, 1 ]]}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided strings" do

          let(:selection) do
            query.send(method, "field_one", "field_two")
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: [[ "field_one", 1 ], [ "field_two", 1 ]]}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided an array of strings" do

          let(:selection) do
            query.send(method, [ "field_one", "field_two" ])
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: [[ "field_one", 1 ], [ "field_two", 1 ]]}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided no options" do

          let(:selection) do
            query.send(method)
          end

          it "does not add any sorting criteria" do
            expect(selection.options).to be_empty
          end

          it "returns the query" do
            expect(selection).to eq(query)
          end

          it_behaves_like "a cloning option"
        end

        context "when provided nil" do

          let(:selection) do
            query.send(method, nil)
          end

          it "does not add any sorting criteria" do
            expect(selection.options).to be_empty
          end

          it "returns the query" do
            expect(selection).to eq(query)
          end

          it_behaves_like "a cloning option"
        end
      end
    end
  end

  describe "#batch_size" do

    context "when provided no options" do

      let(:selection) do
        query.batch_size
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it_behaves_like "a cloning option"
    end

    context "when provided nil" do

      let(:selection) do
        query.batch_size(nil)
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it_behaves_like "a cloning option"
    end

    context "when provided arguments" do

      let(:selection) do
        query.batch_size(500)
      end

      it "adds the field options" do
        expect(selection.options).to eq({ batch_size: 500 })
      end

      it_behaves_like "a cloning option"
    end
  end

  [ :desc, :descending ].each do |method|

    describe "##{method}" do

      context "when using the official mongodb driver syntax" do

        context "when the query is aggregating" do

          let(:selection) do
            query.project(name: 1).send(method, :field_one, :field_two)
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: { "field_one" => -1, "field_two" => -1 }}
            )
          end

          it "adds the sort to the aggregation" do
            expect(selection.pipeline).to include(
              { "$sort" => { "field_one" => -1, "field_two" => -1 }}
            )
          end

          it "does not add multiple entries to the pipeline" do
            expect(selection.pipeline).to_not include(
              { "$sort" => { "field_one" => -1 }}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided symbols" do

          let(:selection) do
            query.send(method, :field_one, :field_two)
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: { "field_one" => -1, "field_two" => -1 }}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided an array of symbols" do

          let(:selection) do
            query.send(method, [ :field_one, :field_two ])
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: { "field_one" => -1, "field_two" => -1 }}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided strings" do

          let(:selection) do
            query.send(method, "field_one", "field_two")
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: { "field_one" => -1, "field_two" => -1 }}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided an array of strings" do

          let(:selection) do
            query.send(method, [ "field_one", "field_two" ])
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: { "field_one" => -1, "field_two" => -1 }}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided no options" do

          let(:selection) do
            query.send(method)
          end

          it "does not add any sorting criteria" do
            expect(selection.options).to be_empty
          end

          it "returns the query" do
            expect(selection).to eq(query)
          end

          it_behaves_like "a cloning option"
        end

        context "when provided nil" do

          let(:selection) do
            query.send(method, nil)
          end

          it "does not add any sorting criteria" do
            expect(selection.options).to be_empty
          end

          it "returns the query" do
            expect(selection).to eq(query)
          end

          it_behaves_like "a cloning option"
        end
      end

      context "when using the mongo-1.x driver syntax" do

        let(:query) do
          Origin::Query.new({}, {}, :mongo1x)
        end

        context "when provided symbols" do

          let(:selection) do
            query.send(method, :field_one, :field_two)
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: [[ :field_one, -1 ], [ :field_two, -1 ]]}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided an array of symbols" do

          let(:selection) do
            query.send(method, [ :field_one, :field_two ])
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: [[ :field_one, -1 ], [ :field_two, -1 ]]}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided strings" do

          let(:selection) do
            query.send(method, "field_one", "field_two")
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: [[ "field_one", -1 ], [ "field_two", -1 ]]}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided an array of strings" do

          let(:selection) do
            query.send(method, [ "field_one", "field_two" ])
          end

          it "adds the sorting criteria" do
            expect(selection.options).to eq(
              { sort: [[ "field_one", -1 ], [ "field_two", -1 ]]}
            )
          end

          it_behaves_like "a cloning option"
        end

        context "when provided no options" do

          let(:selection) do
            query.send(method)
          end

          it "does not add any sorting criteria" do
            expect(selection.options).to be_empty
          end

          it "returns the query" do
            expect(selection).to eq(query)
          end

          it_behaves_like "a cloning option"
        end

        context "when provided nil" do

          let(:selection) do
            query.send(method, nil)
          end

          it "does not add any sorting criteria" do
            expect(selection.options).to be_empty
          end

          it "returns the query" do
            expect(selection).to eq(query)
          end

          it_behaves_like "a cloning option"
        end
      end
    end
  end

  describe "#hint" do

    context "when provided no options" do

      let(:selection) do
        query.hint
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it_behaves_like "a cloning option"
    end

    context "when provided nil" do

      let(:selection) do
        query.hint(nil)
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it_behaves_like "a cloning option"
    end

    context "when provided arguments" do

      context "when the argument is a hash" do

        let(:selection) do
          query.hint("$natural" => 1)
        end

        it "adds the field options" do
          expect(selection.options).to eq({ hint: { "$natural" => 1 }})
        end

        it_behaves_like "a cloning option"
      end
    end
  end

  describe "#limit" do

    context "when provided no options" do

      let(:selection) do
        query.limit
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it_behaves_like "a cloning option"
    end

    context "when provided nil" do

      let(:selection) do
        query.limit(nil)
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it_behaves_like "a cloning option"
    end

    context "when the query is aggregating" do

      let(:selection) do
        query.project(name: 1).limit(10)
      end

      it "adds the field options" do
        expect(selection.options).to eq({ limit: 10 })
      end

      it "adds the limit to the aggregation" do
        expect(selection.pipeline).to include({ "$limit" => 10 })
      end

      it_behaves_like "a cloning option"
    end

    context "when provided arguments" do

      context "when the argument is an integer" do

        let(:selection) do
          query.limit(10)
        end

        it "adds the field options" do
          expect(selection.options).to eq({ limit: 10 })
        end

        it_behaves_like "a cloning option"
      end

      context "when the argument is a float" do

        let(:selection) do
          query.limit(10.25)
        end

        it "adds the field options as an integer" do
          expect(selection.options).to eq({ limit: 10 })
        end

        it_behaves_like "a cloning option"
      end

      context "when the argument is a string" do

        let(:selection) do
          query.limit("10")
        end

        it "adds the field options as an integer" do
          expect(selection.options).to eq({ limit: 10 })
        end

        it_behaves_like "a cloning option"
      end
    end
  end

  describe "#max_scan" do

    context "when provided no options" do

      let(:selection) do
        query.max_scan
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it_behaves_like "a cloning option"
    end

    context "when provided nil" do

      let(:selection) do
        query.max_scan(nil)
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it_behaves_like "a cloning option"
    end

    context "when provided arguments" do

      let(:selection) do
        query.max_scan(500)
      end

      it "adds the field options" do
        expect(selection.options).to eq({ max_scan: 500 })
      end

      it_behaves_like "a cloning option"
    end
  end

  describe "#no_timeout" do

    let(:selection) do
      query.no_timeout
    end

    it "adds the timeout option" do
      expect(selection.options).to eq({ timeout: false })
    end

    it_behaves_like "a cloning option"
  end

  describe "#only" do

    context "when provided no options" do

      let(:selection) do
        query.only
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it_behaves_like "a cloning option"
    end

    context "when provided nil" do

      let(:selection) do
        query.only(nil)
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it_behaves_like "a cloning option"
    end

    context "when provided fields" do

      context "as several arguments" do

        let(:selection) do
          query.only(:first, :second)
        end

        it "adds the field options" do
          expect(selection.options).to eq(
            { fields: { "first" => 1, "second" => 1 }}
          )
        end

        it_behaves_like "a cloning option"
      end

      context "as one argument - array" do

        let(:selection) do
          query.only([:first, :second])
        end

        it "adds the field options" do
          expect(selection.options).to eq(
            { fields: { "first" => 1, "second" => 1 }}
          )
        end

        it_behaves_like "a cloning option"
      end
    end

    context "when #without was called first" do

      let(:selection) do
        query.without(:id).only(:first)
      end

      it "adds both fields to option"  do
        expect(selection.options).to eq(
          { fields: { "id" => 0, "first" => 1 } }
        )
      end
    end
  end

  [ :order, :order_by ].each do |method|

    describe "##{method}" do

      context "when using the official mongodb driver syntax" do

        context "when provided a hash" do

          context "when the query is aggregating" do

            let(:selection) do
              query.project(name: 1).send("#{method}", field_one: 1, field_two: -1)
            end

            it "adds the sorting criteria" do
              expect(selection.options).to eq(
                { sort: { "field_one" => 1, "field_two" => -1 }}
              )
            end

            it "adds the sort to the aggregation" do
              expect(selection.pipeline).to include(
                { "$sort" => { "field_one" => 1, "field_two" => -1 }}
              )
            end

            it "does not add multiple entries to the pipeline" do
              expect(selection.pipeline).to_not include(
                { "$sort" => { "field_one" => 1 }}
              )
            end

            it_behaves_like "a cloning option"
          end

          context "when the hash has integer values" do

            let(:selection) do
              query.send("#{method}", field_one: 1, field_two: -1)
            end

            it "adds the sorting criteria" do
              expect(selection.options).to eq(
                { sort: { "field_one" => 1, "field_two" => -1 }}
              )
            end

            it_behaves_like "a cloning option"
          end

          context "when the hash has symbol values" do

            let(:selection) do
              query.send("#{method}", field_one: :asc, field_two: :desc)
            end

            it "adds the sorting criteria" do
              expect(selection.options).to eq(
                { sort: { "field_one" => 1, "field_two" => -1 }}
              )
            end

            it_behaves_like "a cloning option"
          end

          context "when the hash has string values" do

            let(:selection) do
              query.send("#{method}", field_one: "asc", field_two: "desc")
            end

            it "adds the sorting criteria" do
              expect(selection.options).to eq(
                { sort: { "field_one" => 1, "field_two" => -1 }}
              )
            end

            it_behaves_like "a cloning option"
          end
        end

        context "when provided an array" do

          context "when the array is multi-dimensional" do

            context "when the arrays have integer values" do

              let(:selection) do
                query.send("#{method}", [[ :field_one, 1 ],[ :field_two, -1 ]])
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: { "field_one" => 1, "field_two" => -1 }}
                )
              end

              it_behaves_like "a cloning option"
            end

            context "when the arrays have symbol values" do

              let(:selection) do
                query.send("#{method}", [[ :field_one, :asc ],[ :field_two, :desc ]])
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: { "field_one" => 1, "field_two" => -1 }}
                )
              end

              it_behaves_like "a cloning option"
            end

            context "when the arrays have string values" do

              let(:selection) do
                query.send("#{method}", [[ :field_one, "asc" ],[ :field_two, "desc" ]])
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: { "field_one" => 1, "field_two" => -1 }}
                )
              end

              it_behaves_like "a cloning option"
            end
          end

          context "when the array is selectable keys" do

            let(:selection) do
              query.send("#{method}", [ :field_one.asc, :field_two.desc ])
            end

            it "adds the sorting criteria" do
              expect(selection.options).to eq(
                { sort: { "field_one" => 1, "field_two" => -1 }}
              )
            end

            it_behaves_like "a cloning option"
          end
        end

        context "when provided values" do

          context "when the values are arrays" do

            context "when the values have integer directions" do

              let(:selection) do
                query.send("#{method}", [ :field_one, 1 ],[ :field_two, -1 ])
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: { "field_one" => 1, "field_two" => -1 }}
                )
              end

              it_behaves_like "a cloning option"
            end

            context "when the values have symbol directions" do

              let(:selection) do
                query.send("#{method}", [ :field_one, :asc ],[ :field_two, :desc ])
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: { "field_one" => 1, "field_two" => -1 }}
                )
              end

              it_behaves_like "a cloning option"
            end

            context "when the values have string directions" do

              let(:selection) do
                query.send("#{method}", [ :field_one, "asc" ],[ :field_two, "desc" ])
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: { "field_one" => 1, "field_two" => -1 }}
                )
              end

              it_behaves_like "a cloning option"
            end
          end

          context "when the values are selectable keys" do

            let(:selection) do
              query.send("#{method}", :field_one.asc, :field_two.desc)
            end

            it "adds the sorting criteria" do
              expect(selection.options).to eq(
                { sort: { "field_one" => 1, "field_two" => -1 }}
              )
            end

            it_behaves_like "a cloning option"
          end
        end

        context "when provided a string" do

          context "when the direction is lowercase" do

            context "when abbreviated" do

              let(:selection) do
                query.send("#{method}", "field_one asc, field_two desc")
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: { "field_one" => 1, "field_two" => -1 }}
                )
              end

              it_behaves_like "a cloning option"
            end

            context "when spelled out" do

              let(:selection) do
                query.send("#{method}", "field_one ascending, field_two descending")
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: { "field_one" => 1, "field_two" => -1 }}
                )
              end

              it_behaves_like "a cloning option"
            end
          end

          context "when the direction is uppercase" do

            context "when abbreviated" do

              let(:selection) do
                query.send("#{method}", "field_one ASC, field_two DESC")
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: { "field_one" => 1, "field_two" => -1 }}
                )
              end

              it_behaves_like "a cloning option"
            end

            context "when spelled out" do

              let(:selection) do
                query.send("#{method}", "field_one ASCENDING, field_two DESCENDING")
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: { "field_one" => 1, "field_two" => -1 }}
                )
              end

              it_behaves_like "a cloning option"
            end
          end
        end

        context "when provided no options" do

          let(:selection) do
            query.order_by
          end

          it "returns the query" do
            expect(selection).to eq(query)
          end

          it_behaves_like "a cloning option"
        end

        context "when provided nil" do

          let(:selection) do
            query.send("#{method}", nil)
          end

          it "returns the query" do
            expect(selection).to eq(query)
          end

          it_behaves_like "a cloning option"
        end
      end

      context "when using the mongo-1.x driver syntax" do

        let(:query) do
          Origin::Query.new({}, {}, :mongo1x)
        end

        context "when provided a hash" do

          context "when the hash has integer values" do

            let(:selection) do
              query.send("#{method}", field_one: 1, field_two: -1)
            end

            it "adds the sorting criteria" do
              expect(selection.options).to eq(
                { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
              )
            end

            it_behaves_like "a cloning option"
          end

          context "when the hash has symbol values" do

            let(:selection) do
              query.send("#{method}", field_one: :asc, field_two: :desc)
            end

            it "adds the sorting criteria" do
              expect(selection.options).to eq(
                { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
              )
            end

            it_behaves_like "a cloning option"
          end

          context "when the hash has string values" do

            let(:selection) do
              query.send("#{method}", field_one: "asc", field_two: "desc")
            end

            it "adds the sorting criteria" do
              expect(selection.options).to eq(
                { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
              )
            end

            it_behaves_like "a cloning option"
          end
        end

        context "when provided an array" do

          context "when the array is multi-dimensional" do

            context "when the arrays have integer values" do

              let(:selection) do
                query.send("#{method}", [[ :field_one, 1 ],[ :field_two, -1 ]])
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
                )
              end

              it_behaves_like "a cloning option"
            end

            context "when the arrays have symbol values" do

              let(:selection) do
                query.send("#{method}", [[ :field_one, :asc ],[ :field_two, :desc ]])
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
                )
              end

              it_behaves_like "a cloning option"
            end

            context "when the arrays have string values" do

              let(:selection) do
                query.send("#{method}", [[ :field_one, "asc" ],[ :field_two, "desc" ]])
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
                )
              end

              it_behaves_like "a cloning option"
            end
          end

          context "when the array is selectable keys" do

            let(:selection) do
              query.send("#{method}", [ :field_one.asc, :field_two.desc ])
            end

            it "adds the sorting criteria" do
              expect(selection.options).to eq(
                { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
              )
            end

            it_behaves_like "a cloning option"
          end
        end

        context "when provided values" do

          context "when the values are arrays" do

            context "when the values have integer directions" do

              let(:selection) do
                query.send("#{method}", [ :field_one, 1 ],[ :field_two, -1 ])
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
                )
              end

              it_behaves_like "a cloning option"
            end

            context "when the values have symbol directions" do

              let(:selection) do
                query.send("#{method}", [ :field_one, :asc ],[ :field_two, :desc ])
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
                )
              end

              it_behaves_like "a cloning option"
            end

            context "when the values have string directions" do

              let(:selection) do
                query.send("#{method}", [ :field_one, "asc" ],[ :field_two, "desc" ])
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
                )
              end

              it_behaves_like "a cloning option"
            end
          end

          context "when the values are selectable keys" do

            let(:selection) do
              query.send("#{method}", :field_one.asc, :field_two.desc)
            end

            it "adds the sorting criteria" do
              expect(selection.options).to eq(
                { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
              )
            end

            it_behaves_like "a cloning option"
          end
        end

        context "when provided a string" do

          context "when the direction is lowercase" do

            context "when abbreviated" do

              let(:selection) do
                query.send("#{method}", "field_one asc, field_two desc")
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
                )
              end

              it_behaves_like "a cloning option"
            end

            context "when spelled out" do

              let(:selection) do
                query.send("#{method}", "field_one ascending, field_two descending")
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
                )
              end

              it_behaves_like "a cloning option"
            end
          end

          context "when the direction is uppercase" do

            context "when abbreviated" do

              let(:selection) do
                query.send("#{method}", "field_one ASC, field_two DESC")
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
                )
              end

              it_behaves_like "a cloning option"
            end

            context "when spelled out" do

              let(:selection) do
                query.send("#{method}", "field_one ASCENDING, field_two DESCENDING")
              end

              it "adds the sorting criteria" do
                expect(selection.options).to eq(
                  { sort: [[ :field_one, 1 ], [ :field_two, -1 ]]}
                )
              end

              it_behaves_like "a cloning option"
            end
          end
        end

        context "when provided no options" do

          let(:selection) do
            query.order_by
          end

          it "returns the query" do
            expect(selection).to eq(query)
          end

          it_behaves_like "a cloning option"
        end

        context "when provided nil" do

          let(:selection) do
            query.send("#{method}", nil)
          end

          it "returns the query" do
            expect(selection).to eq(query)
          end

          it_behaves_like "a cloning option"
        end
      end
    end
  end

  describe "#reoder" do

    let(:selection) do
      query.order_by(field_one: 1, field_two: -1)
    end

    let(:reordered) do
      selection.reorder(field_three: 1)
    end

    it "replaces all order options with the new options" do
      expect(reordered.options).to eq(sort: { "field_three" => 1 })
    end
  end

  [ :skip, :offset ].each do |method|

    describe "\##{method}" do

      context "when provided no options" do

        let(:selection) do
          query.send(method)
        end

        it "does not add any options" do
          expect(selection.options).to eq({})
        end

        it "returns the query" do
          expect(selection).to eq(query)
        end

        it_behaves_like "a cloning option"
      end

      context "when provided nil" do

        let(:selection) do
          query.send(method, nil)
        end

        it "does not add any options" do
          expect(selection.options).to eq({})
        end

        it "returns the query" do
          expect(selection).to eq(query)
        end

        it_behaves_like "a cloning option"
      end

      context "when the query is aggregating" do

        let(:selection) do
          query.project(name: 1).skip(10)
        end

        it "adds the field options" do
          expect(selection.options).to eq({ skip: 10 })
        end

        it "adds the skip to the aggregation" do
          expect(selection.pipeline).to include({ "$skip" => 10 })
        end

        it_behaves_like "a cloning option"
      end

      context "when provided arguments" do

        context "when provided an integer" do

          let(:selection) do
            query.send(method, 10)
          end

          it "adds the field options" do
            expect(selection.options).to eq({ skip: 10 })
          end

          it_behaves_like "a cloning option"
        end

        context "when provided a float" do

          let(:selection) do
            query.send(method, 10.25)
          end

          it "adds the field options converted to an integer" do
            expect(selection.options).to eq({ skip: 10 })
          end

          it_behaves_like "a cloning option"
        end

        context "when provided a non number" do

          let(:selection) do
            query.send(method, "10")
          end

          it "adds the field options converted to an integer" do
            expect(selection.options).to eq({ skip: 10 })
          end

          it_behaves_like "a cloning option"
        end
      end
    end
  end

  describe "#slice" do

    context "when provided no options" do

      let(:selection) do
        query.slice
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it_behaves_like "a cloning option"
    end

    context "when provided nil" do

      let(:selection) do
        query.slice(nil)
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it_behaves_like "a cloning option"
    end

    context "when provided a single argument" do

      let(:selection) do
        query.slice(:first => 5)
      end

      it "adds the field options" do
        expect(selection.options).to eq(
          { fields: { "first" => { "$slice" => 5 }}}
        )
      end

      it_behaves_like "a cloning option"
    end

    context "when provided a multiple arguments" do

      let(:selection) do
        query.slice(:first => 5, :second => [ 0, 3 ])
      end

      it "adds the field options" do
        expect(selection.options).to eq({ fields:
          { "first" => { "$slice" => 5 }, "second" => { "$slice" => [ 0, 3 ] }}
        })
      end

      it_behaves_like "a cloning option"
    end

    context "when existing field arguments exist" do

      let(:limited) do
        query.only(:name)
      end

      let(:selection) do
        limited.slice(:first => 5, :second => [ 0, 3 ])
      end

      it "adds the field options" do
        expect(selection.options).to eq({
          fields: {
            "name" => 1,
            "first" => { "$slice" => 5 },
            "second" => { "$slice" => [ 0, 3 ] }
          }
        })
      end

      it_behaves_like "a cloning option"
    end
  end

  describe "#snapshot" do

    let(:selection) do
      query.snapshot
    end

    it "adds the snapshot option" do
      expect(selection.options).to eq({ snapshot: true })
    end

    it_behaves_like "a cloning option"
  end

  describe "#comment" do

    let(:selection) do
      query.comment('slow query')
    end

    it "adds the comment option" do
      expect(selection.options).to eq({ comment: 'slow query' })
    end

    it_behaves_like "a cloning option"
  end

  describe "#cursor_type" do

    let(:selection) do
      query.cursor_type(:tailable)
    end

    it "adds the cursor type option" do
      expect(selection.options).to eq({ cursor_type: :tailable })
    end

    it_behaves_like "a cloning option"
  end

  describe "#without" do

    context "when provided no options" do

      let(:selection) do
        query.without
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it_behaves_like "a cloning option"
    end

    context "when provided nil" do

      let(:selection) do
        query.without(nil)
      end

      it "does not add any options" do
        expect(selection.options).to eq({})
      end

      it "returns the query" do
        expect(selection).to eq(query)
      end

      it_behaves_like "a cloning option"
    end

    context "when provided fields" do

      context "as sevaral arguments" do

        let(:selection) do
          query.without(:first, :second)
        end

        it "adds the field options" do
          expect(selection.options).to eq(
            { fields: { "first" => 0, "second" => 0 }}
          )
        end

        it_behaves_like "a cloning option"
      end

      context "as one argument - array" do

        let(:selection) do
          query.without([:first, :second])
        end

        it "adds the field options" do
          expect(selection.options).to eq(
            { fields: { "first" => 0, "second" => 0 }}
          )
        end

        it_behaves_like "a cloning option"
      end
    end

    context "when #only was called before" do
      let(:selection) do
        query.only(:first).without(:id)
      end

      it "adds both fields to options" do
        expect(selection.options).to eq(
          { fields: { "first" => 1, "id" => 0 } }
        )
      end
    end
  end
end
