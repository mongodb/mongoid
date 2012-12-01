require "spec_helper"

describe Mongoid::Sessions::Factory do

  describe ".create" do

    context "when provided a name" do

      context "when the configuration exists" do

        context "when the configuration is standard" do

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

        context "when the configuration has no ports" do

          let(:config) do
            {
              default: { hosts: [ "127.0.0.1" ], database: database_id },
              secondary: { hosts: [ "localhost" ], database: database_id }
            }
          end

          before do
            Mongoid::Config.sessions = config
          end

          let(:session) do
            described_class.create(:secondary)
          end

          let(:default) do
            described_class.create(:default)
          end

          let(:cluster) do
            session.cluster
          end

          it "returns a session" do
            session.should be_a(Moped::Session)
          end

          it "sets the cluster's seed ports to 27017" do
            cluster.seeds.should eq([ "localhost:27017" ])
          end

          it "sets ips with no ports to 27017" do
            default.cluster.seeds.should eq([ "127.0.0.1:27017" ])
          end
        end

        context "when configured via a uri" do

          context "when the uri has a single host:port" do

            let(:config) do
              {
                default: { hosts: [ "localhost:27017" ], database: database_id },
                secondary: { uri: "mongodb://localhost:27017/mongoid_test" }
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

            it "sets the database" do
              session.options[:database].should eq("mongoid_test")
            end

            it "sets the database in the configuration" do
              session
              Mongoid.sessions[:secondary].should include(:database)
            end

            it "sets the hosts in the configuration" do
              session
              Mongoid.sessions[:secondary].should include(:hosts)
            end

            it "removes the uri from the configuration" do
              session
              Mongoid.sessions[:secondary].should_not include(:uri)
            end
          end

          context "when the uri has multiple host:port pairs" do

            let(:config) do
              {
                default: { hosts: [ "localhost:27017" ], database: database_id },
                secondary: { uri: "mongodb://localhost:27017,localhost:27017/mongoid_test" }
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
              cluster.seeds.should eq([ "localhost:27017", "localhost:27017" ])
            end

            it "sets the database" do
              session.options[:database].should eq("mongoid_test")
            end

            it "sets the database in the configuration" do
              session
              Mongoid.sessions[:secondary].should include(:database)
            end

            it "sets the hosts in the configuration" do
              session
              Mongoid.sessions[:secondary].should include(:hosts)
            end

            it "removes the uri from the configuration" do
              session
              Mongoid.sessions[:secondary].should_not include(:uri)
            end
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

    context "when nil is provided and no default config" do

      let(:config) { nil }

      before do
        Mongoid.sessions[:default] = nil
      end

      it "raises NoSessionsConfig error" do
        expect{ Mongoid::Sessions::Factory.create(config) }.to raise_error(Mongoid::Errors::NoSessionsConfig)
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

  context "when options are provided with string keys" do

    let(:config) do
      {
        default: {
          hosts: [ "localhost:27017" ],
          database: database_id,
          options: {
            "down_interval" => 10,
            "max_retries" => 5,
            "refresh_interval" => 30,
            "retry_interval" => 0.1
          }
        }
      }
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

    it "sets the cluster down interval" do
      cluster.down_interval.should eq(10)
    end

    it "sets the cluster max retries" do
      cluster.max_retries.should eq(5)
    end

    it "sets the cluster refresh interval" do
      cluster.refresh_interval.should eq(30)
    end

    it "sets the cluster retry interval" do
      cluster.retry_interval.should eq(0.1)
    end
  end
end
