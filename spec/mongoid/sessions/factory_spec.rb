require "spec_helper"

describe Mongoid::Sessions::Factory do

  describe ".create" do

    context "when provided a name" do

      context "when the configuration exists" do

        context "when no uri provided" do

          let(:config) do
            {
              default: { hosts: [ "localhost:27017" ], database: database_id },
              secondary: { hosts: [ "localhost:27017" ], database: database_id }
            }
          end

          before do
            Mongoid::Config.sessions = config
          end

          let(:session) do
            described_class.create(:secondary)
          end

          let(:cluster) do
            session.cluster
          end

          it "returns a session" do
            session.should be_a(Moped::Session)
          end

          it "sets the cluster's seeds" do
            cluster.seeds.should eq([ "localhost:27017" ])
          end
        end

        context "when uri provided" do

          let(:config) do
            {
              default: { uri: "mongodb://localhost:27017/#{database_id}" },
              secondary: { uri: "mongodb://localhost:27017/#{database_id}" }
            }
          end

          before do
            Mongoid::Config.sessions = config
          end

          let(:session) do
            described_class.create(:secondary)
          end

          let(:cluster) do
            session.cluster
          end

          it "returns a session" do
            session.should be_a(Moped::Session)
          end

          it "sets the cluster's seeds" do
            cluster.seeds.should eq([ "localhost:27017" ])
          end
        end
      end

      context "when the configuration does not exist" do

        it "raises an error" do
          expect {
            described_class.create(:unknown)
          }.to raise_error(Mongoid::Errors::NoSessionConfig)
        end
      end
    end

    context "when no name is provided" do

      let(:config) do
        { default: { hosts: ["localhost:27017"], database: database_id }}
      end

      before do
        Mongoid::Config.sessions = config
      end

      let(:session) do
        described_class.create
      end

      let(:cluster) do
        session.cluster
      end

      it "returns the default session" do
        session.should be_a(Moped::Session)
      end

      it "sets the cluster's seeds" do
        cluster.seeds.should eq([ "localhost:27017" ])
      end
    end
  end

  describe ".default" do

    let(:config) do
      { default: { hosts: ["localhost:27017"], database: database_id }}
    end

    before do
      Mongoid::Config.sessions = config
    end

    let(:session) do
      described_class.default
    end

    let(:cluster) do
      session.cluster
    end

    it "returns the default session" do
      session.should be_a(Moped::Session)
    end

    it "sets the cluster's seeds" do
      cluster.seeds.should eq([ "localhost:27017" ])
    end
  end

  describe ".uri?" do

    context "when no uri provided" do

      let(:config) do
        {}
      end

      it "returns false" do
        described_class.send(:uri?, config).should be_false
      end
    end

    context "when uri provided" do

      let(:config) do
        { uri: "mongodb://user:pass@example.com:port/db" }
      end

      it "returns true" do
        described_class.send(:uri?, config).should be_true
      end
    end
  end

  describe ".expand_uri" do

    let(:config) do
      { uri: "mongodb://user:pass@example.com:100/db" }
    end

    let(:expanded) do
      described_class.send(:expand_uri, config)
    end

    it "sets username" do
      expanded[:username].should eq("user")
    end

    it "sets password" do
      expanded[:password].should eq("pass")
    end

    it "sets hosts" do
      expanded[:hosts].should eq(["example.com:100"])
    end

    it "sets database" do
      expanded[:database].should eq("db")
    end
  end
end
