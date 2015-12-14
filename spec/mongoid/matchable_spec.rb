require "spec_helper"

describe Mongoid::Matchable do

  describe "#matches?" do

    context "when document is embeded" do

      let(:document) do
        Address.new(street: "Clarkenwell Road")
      end

      before do
        document.locations << Location.new(
          name: 'No.1',
          info: { 'door' => 'Red'},
          occupants: [{'name' => 'Tim'}]
        )
      end

      context "when the attributes do not match" do

        let(:selector) do
          { name: { "$in" => ["No.2"], "$ne" => nil } }
        end

        it "returns false" do
          expect(document.locations.first.matches?(selector)).to be false
        end

        context "when just change the selector order" do

          let(:selector) do
            { name: { "$ne" => nil, "$in" => ["No.2"] } }
          end

          it "returns false " do
            expect(document.locations.first.matches?(selector)).to be false
          end
        end
      end

      context "when matching embedded hash values" do

        context "when the contents match" do

          let(:selector) do
            { "info.door" => "Red" }
          end

          it "returns true" do
            expect(document.locations.first.matches?(selector)).to be true
          end
        end

        context "when the contents do not match" do

          let(:selector) do
            { "info.door" => "Blue" }
          end

          it "returns false" do
            expect(document.locations.first.matches?(selector)).to be false
          end
        end

        context "when the contents do not exist" do

          let(:selector) do
            { "info.something_else" => "Red" }
          end

          it "returns false" do
            expect(document.locations.first.matches?(selector)).to be false
          end
        end
      end

      context "when matching values of multiple embedded hashes" do

        context "when the contents match" do

          let(:selector) do
            { "occupants.name" => "Tim" }
          end

          it "returns true" do
            expect(document.locations.first.matches?(selector)).to be true
          end
        end

        context "when the contents do not match" do

          let(:selector) do
            { "occupants.name" => "Lyle" }
          end

          it "returns false" do
            expect(document.locations.first.matches?(selector)).to be false
          end
        end

        context "when the contents do not exist" do

          let(:selector) do
            { "occupants.something_else" => "Tim" }
          end

          it "returns false" do
            expect(document.locations.first.matches?(selector)).to be false
          end
        end
      end

    end

    context "when performing simple matching" do

      let(:document) do
        Address.new(street: "Clarkenwell Road")
      end

      context "when the attributes match" do

        let(:selector) do
          { street: "Clarkenwell Road" }
        end

        it "returns true" do
          expect(document.matches?(selector)).to be true
        end
      end

      context "when the attributes dont match" do

        let(:selector) do
          { street: "Broadway Ave" }
        end

        it "returns false" do
          expect(document.matches?(selector)).to be false
        end
      end
    end

    context "when performing complex matching" do

      let(:document) do
        Address.new(
          services: ["first", "second", "third"],
          number: 100,
          map: { key: "value" },
          street: "Clarkenwell Road"
        )
      end

      context "with an $all selector" do

        context "when the attribute includes all of the values" do

          let(:selector) do
            { services: { "$all" => [ "first", "second" ] } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes doesn't include all of the values" do

          let(:selector) do
            { services: { "$all" => [ "second", "third", "fourth" ] } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with an $exists selector" do

        context "when the attributes match" do

          let(:selector) do
            { services: { "$exists" => true } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { services: { "$exists" => false } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with a $gt selector" do

        context "when the attributes match" do

          let(:selector) do
            { number: { "$gt" => 50 } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { number: { "$gt" => 200 } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with a $gt selector as a symbol" do

        context "when the attributes match" do

          let(:selector) do
            { number: { :$gt => 50 } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { number: { :$gt => 200 } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with a $gte selector" do

        context "when the attributes match" do

          let(:selector) do
            { number: { "$gte" => 100 } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { number: { "$gte" => 200 } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with an $in selector on Array" do

        context "when the attributes match" do

          let(:selector) do
            { services: { "$in" => [ /\Afir.*\z/, "second" ] } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { number: { "$in" => [ "none" ] } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with a $not selector" do

        context "regexes" do

          context "when the predicate matches" do

            let(:selector) do
              {
                street: {"$not" => /Avenue/}
              }
            end

            it "returns true" do
              expect(document.matches?(selector)).to be true
            end
          end

          context "when the predicate does not match" do

            let(:selector) do
              {
                street: {"$not" => /Road/}
              }
            end

            it "returns false" do
              expect(document.matches?(selector)).to be false
            end
          end
        end

        context "other operators" do

          context "numerical comparisons" do

            context "$lt and $gt" do

              context "when the predicate matches" do

                let(:selector) do
                  {
                    number: {"$not" => {"$lt" => 0}}
                  }
                end

                it "returns true" do
                  expect(document.matches?(selector)).to be true
                end
              end

              context "when the predicate does not match" do

                let(:selector) do
                  {
                    number: {"$not" => {"$gt" => 50}}
                  }
                end

                it "returns false" do
                  expect(document.matches?(selector)).to be false
                end
              end
            end

            context "$in" do

              context "when the predicate matches" do

                let(:selector) do
                  {
                    number: {"$not" => {"$in" => [10]}}
                  }
                end

                it "returns true" do
                  expect(document.matches?(selector)).to be true
                end
              end

              context "when the predicate does not match" do

                let(:selector) do
                  {
                    number: {"$not" => {"$in" => [100]}}
                  }
                end

                it "returns false" do
                  expect(document.matches?(selector)).to be false
                end
              end
            end
          end
        end

        context "symbol keys" do

          context "when the predicate matches" do

            let(:selector) do
              {
                street: {:$not => /Avenue/}
              }
            end

            it "returns true" do
              expect(document.matches?(selector)).to be true
            end
          end

          context "when the predicate does not match" do

            let(:selector) do
              {
                street: {:$not => /Road/}
              }
            end

            it "returns false" do
              expect(document.matches?(selector)).to be false
            end
          end
        end
      end

      context "with an $in selector" do

        context "when the attributes match" do

          let(:selector) do
            { number: { "$in" => [ 100, 200 ] } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { number: { "$in" => [ 200, 300 ] } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with a $lt selector" do

        context "when the attributes match" do

          let(:selector) do
            { number: { "$lt" => 200 } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { number: { "$lt" => 50 } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with a $lte selector" do

        context "when the attributes match" do

          let(:selector) do
            { number: { "$lte" => 200 } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { number: { "$lte" => 50 } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with an $ne selector" do

        context "when the attributes match" do

          let(:selector) do
            { number: { "$ne" => 200 } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { number: { "$ne" => 100 } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with a $nin selector on Array" do

        context "when the attributes match" do

          let(:selector) do
            { services: { "$nin" => [ "none" ] } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { services: { "$nin" => [ "first" ] } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with a $nin selector" do

        context "when the attributes match" do

          let(:selector) do
            { number: { "$nin" => [ 1, 2, 3 ] } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { number: { "$nin" => [ 100 ] } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with an $or selector" do

        context "when the attributes match" do

          let(:selector) do
            { "$or" => [ { number: 10 }, { number: { "$gt" => 99 } } ] }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { "$or" => [ { number: 10 }, { number: { "$lt" => 99 } } ] }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with a $size selector" do

        context "when the attributes match" do

          let(:selector) do
            { services: { "$size" => 3 } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { services: { "$size" => 5 } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end

      context "with a hash value" do

        context "when the attributes match" do

          let(:selector) do
            { map: { key: "value" } }
          end

          it "returns true" do
            expect(document.matches?(selector)).to be true
          end
        end

        context "when the attributes do not match" do

          let(:selector) do
            { map: { key: "value2" } }
          end

          it "returns false" do
            expect(document.matches?(selector)).to be false
          end
        end
      end
    end
  end
end
