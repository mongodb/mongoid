# frozen_string_literal: true

require "spec_helper"

describe Hash do

  describe "#__add__" do

    context "when the other object is a hash" do

      context "when a key matches" do

        context "when the existing value is a non-enumerable" do

          context "when the added value is non-enumerable" do

            context "when the values are unique" do

              let(:hash) do
                { "$in" => 5 }
              end

              before do
                hash.__add__({ "$in" => 6 })
              end

              it "sets the new array" do
                expect(hash).to eq({ "$in" => [ 5, 6 ] })
              end
            end

            context "when the values are not unique" do

              let(:hash) do
                { "$in" => 5 }
              end

              before do
                hash.__add__({ "$in" => 5 })
              end

              it "keeps the old value" do
                expect(hash).to eq({ "$in" => 5 })
              end
            end
          end
        end

        context "when the existing value is an array" do

          context "when the values are unique" do

            let(:hash) do
              { "$in" => [ 5, 6 ] }
            end

            before do
              hash.__add__({ "$in" => [ 7, 8 ] })
            end

            it "sets the new array" do
              expect(hash).to eq({ "$in" => [ 5, 6, 7, 8 ] })
            end
          end

          context "when the values are not unique" do

            let(:hash) do
              { "$in" => [ 5, 6 ] }
            end

            before do
              hash.__add__({ "$in" => [ 6, 7 ] })
            end

            it "sets a new unique array" do
              expect(hash).to eq({ "$in" => [ 5, 6, 7 ] })
            end
          end
        end
      end

      context "when a key does not match" do

        let(:hash) do
          { "$all" => [ 1, 2, 3 ] }
        end

        before do
          hash.__add__({ "$in" => [ 1, 2 ] })
        end

        it "merges in the new hash" do
          expect(hash).to eq({
            "$all" => [ 1, 2, 3 ],
            "$in" => [ 1, 2 ]
          })
        end
      end
    end
  end

  describe "#__expand_complex" do

    let(:hash) do
      {
        :test1.elem_match => {
          :test2.elem_match => {
            :test3.in => ["value1"]
          }
        }
      }
    end

    context "when the hash is nested multiple levels" do

      let(:expanded) do
        hash.__expand_complex__
      end

      let(:expected) do
        {
          "test1"=> {
            "$elemMatch"=> {
              "test2"=> {
                "$elemMatch"=> {
                  "test3"=> { "$in"=> ["value1"] }
                }
              }
            }
          }
        }
      end

      it "expands the nested values" do
        expect(expanded).to eq(expected)
      end
    end
  end

  describe "#__intersect__" do

    context "when the other object is a hash" do

      context "when a key matches" do

        context "when the existing value is a non-enumerable" do

          context "when the intersected value is non-enumerable" do

            context "when the values intersect" do

              let(:hash) do
                { "$in" => 5 }
              end

              before do
                hash.__intersect__({ "$in" => 5 })
              end

              it "sets the intersected array" do
                expect(hash).to eq({ "$in" => [ 5 ] })
              end
            end

            context "when the values do not intersect" do

              let(:hash) do
                { "$in" => 5 }
              end

              before do
                hash.__intersect__({ "$in" => 6 })
              end

              it "sets the empty array" do
                expect(hash).to eq({ "$in" => [] })
              end
            end
          end
        end

        context "when the existing value is an array" do

          context "when the values intersect" do

            let(:hash) do
              { "$in" => [ 5, 6 ] }
            end

            before do
              hash.__intersect__({ "$in" => [ 6, 7 ] })
            end

            it "sets the intersected array" do
              expect(hash).to eq({ "$in" => [ 6 ] })
            end
          end

          context "when the values do not intersect" do

            let(:hash) do
              { "$in" => [ 5, 6 ] }
            end

            before do
              hash.__intersect__({ "$in" => [ 7, 8 ] })
            end

            it "sets the empty array" do
              expect(hash).to eq({ "$in" => [] })
            end
          end
        end
      end

      context "when a key does not match" do

        let(:hash) do
          { "$all" => [ 1, 2, 3 ] }
        end

        before do
          hash.__intersect__({ "$in" => [ 1, 2 ] })
        end

        it "merges in the new hash" do
          expect(hash).to eq({
            "$all" => [ 1, 2, 3 ],
            "$in" => [ 1, 2 ]
          })
        end
      end
    end
  end

  describe "#__union__" do

    context "when the other object is a hash" do

      context "when a key matches" do

        context "when the existing value is a non-enumerable" do

          context "when the unioned value is non-enumerable" do

            context "when the values are the same" do

              let(:hash) do
                { "$in" => 5 }
              end

              before do
                hash.__union__({ "$in" => 5 })
              end

              it "sets the unioned array" do
                expect(hash).to eq({ "$in" => [ 5 ] })
              end
            end

            context "when the values are different" do

              let(:hash) do
                { "$in" => 5 }
              end

              before do
                hash.__union__({ "$in" => 6 })
              end

              it "sets the empty array" do
                expect(hash).to eq({ "$in" => [ 5, 6 ] })
              end
            end
          end
        end

        context "when the existing value is an array" do

          let(:hash) do
            { "$in" => [ 5, 6 ] }
          end

          before do
            hash.__union__({ "$in" => [ 6, 7 ] })
          end

          it "sets the unioned array" do
            expect(hash).to eq({ "$in" => [ 5, 6, 7 ] })
          end
        end
      end

      context "when a key does not match" do

        let(:hash) do
          { "$all" => [ 1, 2, 3 ] }
        end

        before do
          hash.__union__({ "$in" => [ 1, 2 ] })
        end

        it "merges in the new hash" do
          expect(hash).to eq({
            "$all" => [ 1, 2, 3 ],
            "$in" => [ 1, 2 ]
          })
        end
      end
    end
  end
end
