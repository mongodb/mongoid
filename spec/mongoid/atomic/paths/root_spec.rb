require "spec_helper"

describe Mongoid::Atomic::Paths::Root do

  let(:person) do
    Person.new
  end

  let(:root) do
    described_class.new(person)
  end

  describe "#document" do

    it "returns the document" do
      root.document.should eq(person)
    end
  end

  describe "#path" do

    it "returns an empty string" do
      root.path.should be_empty
    end
  end

  describe "#position" do

    it "returns an empty string" do
      root.position.should be_empty
    end
  end

  describe "#insert_modifier" do

    let(:address) do
      person.addresses.build
    end

    let(:root) do
      described_class.new(address)
    end

    it "raises a mixed relations error" do
      expect { root.insert_modifier }.to raise_error(Mongoid::Errors::InvalidPath)
    end
  end

  describe "#selector" do

    context "when using a shard key" do

      let(:profile) do
        Profile.new(name: "google")
      end

      let(:root) do
        described_class.new(profile)
      end

      it "returns the id and shard key in the hash" do
        root.selector.should eq({ "_id" => profile.id, "name" => profile.name })
      end
    end

    context "when not using a shard key" do

      context "when using object ids" do

        it "returns the hash with the id" do
          root.selector.should eq({ "_id" => person.id })
        end
      end

      context "when using a composite key" do

        let(:account) do
          Account.new(name: "savings")
        end

        let(:root) do
          described_class.new(account)
        end

        context "when the composite key has changed" do

          before do
            account.new_record = false
            account.name = "current"
          end

          it "returns the hash with the old key" do
            root.selector.should eq({ "_id" => "savings" })
          end
        end

        context "when the composite key has not changed" do

          it "returns the hash with the key" do
            root.selector.should eq({ "_id" => "savings" })
          end
        end
      end
    end
  end
end
