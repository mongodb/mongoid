require "spec_helper"

describe Mongoid::Selectable do

  describe "#atomic_selector" do

    context "when the document is a root document" do

      context "when the document has a shard key" do

        let(:profile) do
          Profile.create(name: "google")
        end

        let!(:selector) do
          profile.atomic_selector
        end

        it "returns the id and shard key in the hash" do
          expect(selector).to eq({ "_id" => profile.id, "name" => profile.name })
        end
      end

      context "when the document does not have a shard key" do

        context "when using object ids" do

          let(:band) do
            Band.create
          end

          let(:selector) do
            band.atomic_selector
          end

          it "returns the hash with the id" do
            expect(selector).to eq({ "_id" => band.id })
          end
        end

        context "when using a custom id" do

          let(:account) do
            Account.create(name: "savings")
          end

          let(:selector) do
            account.atomic_selector
          end

          context "when the id has not changed" do

            it "returns the hash with the key" do
              expect(selector).to eq({ "_id" => "savings" })
            end
          end

          context "when the composite key has changed" do

            before do
              account.new_record = false
              account.name = "current"
            end

            it "returns the hash with the old key" do
              expect(selector).to eq({ "_id" => "savings" })
            end
          end
        end
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      context "when the document is an embeds one" do

        let(:name) do
          person.create_name(first_name: "test", last_name: "user")
        end

        it "returns the hash with the selector" do
          expect(name.atomic_selector).to eq(
            { "_id" => person.id, "name._id" => name.id }
          )
        end
      end

      context "when the document is an embeds many" do

        let(:address) do
          person.addresses.create(street: "kreuzbergstr")
        end

        it "returns the hash with the selector" do
          expect(address.atomic_selector).to eq(
            { "_id" => person.id, "addresses._id" => address.id }
          )
        end

        context "when the document's id changes" do

          before do
            address._id = "hobrecht"
          end

          it "returns only the parent selector" do
            expect(address.atomic_selector).to eq(person.atomic_selector)
          end
        end

        context "when the document is embedded multiple levels" do

          let(:location) do
            address.locations.create
          end

          it "returns a hash with the selector" do
            expect(location.atomic_selector).to eq(
              {
                "_id" => person.id,
                "addresses._id" => address.id,
                "addresses.0.locations._id" => location.id
              }
            )
          end
        end
      end
    end
  end
end
