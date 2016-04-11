require "spec_helper"

describe Hash do
  using Mongoid::Refinements

  describe "#evolve_object_id" do

    context "when values have object id strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id.to_s }
      end

      let(:evolved) do
        hash.evolve_object_id
      end

      it "converts each value in the hash" do
        expect(evolved[:field]).to eq(object_id)
      end
    end

    context "when values have object ids" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id }
      end

      let(:evolved) do
        hash.evolve_object_id
      end

      it "converts each value in the hash" do
        expect(evolved[:field]).to eq(object_id)
      end
    end

    context "when values have empty strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: "" }
      end

      let(:evolved) do
        hash.evolve_object_id
      end

      it "retains the empty string values" do
        expect(evolved[:field]).to be_empty
      end
    end

    context "when values have nils" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: nil }
      end

      let(:evolved) do
        hash.evolve_object_id
      end

      it "retains the nil values" do
        expect(evolved[:field]).to be_nil
      end
    end
  end

  describe "#mongoize_object_id" do

    context "when values have object id strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id.to_s }
      end

      let(:mongoized) do
        hash.mongoize_object_id
      end

      it "converts each value in the hash" do
        expect(mongoized[:field]).to eq(object_id)
      end
    end

    context "when values have object ids" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id }
      end

      let(:mongoized) do
        hash.mongoize_object_id
      end

      it "converts each value in the hash" do
        expect(mongoized[:field]).to eq(object_id)
      end
    end

    context "when values have empty strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: "" }
      end

      let(:mongoized) do
        hash.mongoize_object_id
      end

      it "converts the empty strings to nil" do
        expect(mongoized[:field]).to be_nil
      end
    end

    context "when values have nils" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: nil }
      end

      let(:mongoized) do
        hash.mongoize_object_id
      end

      it "retains the nil values" do
        expect(mongoized[:field]).to be_nil
      end
    end
  end

  describe "#consolidate" do

    context "when the hash already contains the key" do

      context "when the $set is first" do

        let(:hash) do
          { "$set" => { name: "Tool" }, likes: 10, "$inc" => { plays: 1 }}
        end

        let(:consolidated) do
          hash.consolidate(Band)
        end

        it "moves the non hash values under the provided key" do
          expect(consolidated).to eq({
            "$set" => { name: "Tool", likes: 10 }, "$inc" => { plays: 1 }
          })
        end
      end

      context "when the $set is not first" do

        let(:hash) do
          { likes: 10, "$inc" => { plays: 1 }, "$set" => { name: "Tool" }}
        end

        let(:consolidated) do
          hash.consolidate(Band)
        end

        it "moves the non hash values under the provided key" do
          expect(consolidated).to eq({
            "$set" => { likes: 10, name: "Tool" }, "$inc" => { plays: 1 }
          })
        end
      end
    end

    context "when the hash does not contain the key" do

      let(:hash) do
        { likes: 10, "$inc" => { plays: 1 }, name: "Tool"}
      end

      let(:consolidated) do
        hash.consolidate(Band)
      end

      it "moves the non hash values under the provided key" do
        expect(consolidated).to eq({
          "$set" => { likes: 10, name: "Tool" }, "$inc" => { plays: 1 }
        })
      end
    end
  end

  context "when the hash key is a string" do

    let(:hash) do
      { "100" => { "name" => "hundred" } }
    end

    let(:nested) do
      hash.nested_value("100.name")
    end

    it "should retrieve a nested value under the provided key" do
      expect(nested).to eq "hundred"
    end
  end

  context "when the hash key is an integer" do

    let(:hash) do
      { 100 => { "name" => "hundred" } }
    end

    let(:nested) do
      hash.nested_value("100.name")
    end

    it "should retrieve a nested value under the provided key" do
      expect(nested).to eq("hundred")
    end
  end

  describe ".demongoize" do

    let(:hash) do
      { field: 1 }
    end

    it "returns the hash" do
      expect(Hash.demongoize(hash)).to eq(hash)
    end
  end

  describe ".mongoize" do

    context "when object isn't nil" do

      let(:date) do
        Date.new(2012, 1, 1)
      end

      let(:hash) do
        { date: date }
      end

      let(:mongoized) do
        Hash.mongoize(hash)
      end

      it "mongoizes each element in the hash" do
        expect(mongoized[:date]).to be_a(Time)
      end

      it "converts the elements properly" do
        expect(mongoized[:date]).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
      end
    end

    context "when object is nil" do
      let(:mongoized) do
        Hash.mongoize(nil)
      end

      it "returns nil" do
        expect(mongoized).to be_nil
      end
    end
  end

  describe "#mongoize" do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:hash) do
      { date: date }
    end

    let(:mongoized) do
      hash.mongoize
    end

    it "mongoizes each element in the hash" do
      expect(mongoized[:date]).to be_a(Time)
    end

    it "converts the elements properly" do
      expect(mongoized[:date]).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
    end
  end

  describe "#resizable?" do

    it "returns true" do
      expect({}.resizable?).to be true
    end
  end

  describe ".resizable?" do

    it "returns true" do
      expect(Hash.resizable?).to be true
    end
  end

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

  describe "#update_values" do

    let(:hash) do
      { field: "1" }
    end

    before do
      hash.update_values(&:to_i)
    end

    it "updates each value in the hash" do
      expect(hash).to eq({ field: 1 })
    end
  end
end
