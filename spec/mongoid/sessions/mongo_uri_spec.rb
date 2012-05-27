require "spec_helper"

describe Mongoid::Sessions::MongoUri do

  let(:single) do
    "mongodb://user:pass@localhost:27017/mongoid_test"
  end

  let(:multiple) do
    "mongodb://localhost:27017,localhost:27017/mongoid_test"
  end

  describe "#database" do

    let(:uri) do
      described_class.new(single)
    end

    it "returns the database name" do
      uri.database.should eq("mongoid_test")
    end
  end

  describe "#hosts" do

    context "when a single node is provided" do

      let(:uri) do
        described_class.new(single)
      end

      it "returns an array with 1 node" do
        uri.hosts.should eq([ "localhost:27017" ])
      end
    end

    context "when multiple nodes are provided" do

      let(:uri) do
        described_class.new(multiple)
      end

      it "returns an array with 2 nodes" do
        uri.hosts.should eq([ "localhost:27017", "localhost:27017" ])
      end
    end
  end

  describe "#password" do

    let(:uri) do
      described_class.new(single)
    end

    it "returns the password" do
      uri.password.should eq("pass")
    end
  end

  describe "#to_hash" do

    context "when a user and password are not provided" do

      let(:uri) do
        described_class.new(multiple)
      end

      it "does not include the username and password" do
        uri.to_hash.should eq({
          hosts: [ "localhost:27017", "localhost:27017" ],
          database: "mongoid_test"
        })
      end
    end

    context "when a user and password are provided" do

      let(:uri) do
        described_class.new(single)
      end

      it "includes the username and password" do
        uri.to_hash.should eq({
          hosts: [ "localhost:27017" ],
          database: "mongoid_test",
          username: "user",
          password: "pass"
        })
      end
    end
  end

  describe "#username" do

    let(:uri) do
      described_class.new(single)
    end

    it "returns the userame" do
      uri.username.should eq("user")
    end
  end
end
