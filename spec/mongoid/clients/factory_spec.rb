require "spec_helper"

describe Mongoid::Clients::Factory do

  describe ".create" do

    context "when provided a name" do

      context "when the configuration exists" do

        context "when the configuration is standard" do

          let(:config) do
            {
              default: { hosts: [ "127.0.0.1:27017" ], database: database_id },
              secondary: { hosts: [ "127.0.0.1:27017" ], database: database_id }
            }
          end

          before do
            Mongoid::Config.send(:clients=, config)
          end

          let(:client) do
            described_class.create(:secondary)
          end

          let(:cluster) do
            client.cluster
          end

          it "returns a client" do
            expect(client).to be_a(Mongo::Client)
          end

          it "sets the cluster's seeds" do
            expect(cluster.addresses.first.to_s).to eq("127.0.0.1:27017")
          end
        end

        context "when the configuration has no ports" do

          let(:config) do
            {
              default: { hosts: [ "127.0.0.1" ], database: database_id },
              secondary: { hosts: [ "127.0.0.1" ], database: database_id }
            }
          end

          before do
            Mongoid::Config.send(:clients=, config)
          end

          let(:client) do
            described_class.create(:secondary)
          end

          let(:default) do
            described_class.create(:default)
          end

          let(:cluster) do
            client.cluster
          end

          it "returns a client" do
            expect(client).to be_a(Mongo::Client)
          end

          it "sets the cluster's seed ports to 27017" do
            expect(cluster.addresses.first.to_s).to eq("127.0.0.1:27017")
          end

          it "sets ips with no ports to 27017" do
            expect(default.cluster.addresses.first.to_s).to eq("127.0.0.1:27017")
          end
        end

        context "when configured via a uri" do

          context "when the uri has a single host:port" do

            let(:config) do
              {
                default: { hosts: [ "127.0.0.1:27017" ], database: database_id },
                secondary: { uri: "mongodb://127.0.0.1:27017/mongoid_test" }
              }
            end

            before do
              Mongoid::Config.send(:clients=, config)
            end

            let(:client) do
              described_class.create(:secondary)
            end

            let(:cluster) do
              client.cluster
            end

            it "returns a client" do
              expect(client).to be_a(Mongo::Client)
            end

            it "sets the cluster's seeds" do
              expect(cluster.addresses.first.to_s).to eq("127.0.0.1:27017")
            end

            it "sets the database" do
              expect(client.options[:database]).to eq("mongoid_test")
            end
          end

          context "when the uri has multiple host:port pairs" do

            let(:config) do
              {
                default: { hosts: [ "127.0.0.1:27017" ], database: database_id },
                secondary: { uri: "mongodb://127.0.0.1:27017,127.0.0.1:27018/mongoid_test" }
              }
            end

            before do
              Mongoid::Config.send(:clients=, config)
            end

            let(:client) do
              described_class.create(:secondary)
            end

            let(:cluster) do
              client.cluster
            end

            let(:seeds) do
              cluster.addresses.map{ |address| address.to_s }
            end

            it "returns a client" do
              expect(client).to be_a(Mongo::Client)
            end

            it "sets the cluster's seeds" do
              expect(seeds).to eq([ "127.0.0.1:27017", "127.0.0.1:27018" ])
            end
          end
        end
      end

      context "when the configuration does not exist" do

        it "raises an error" do
          expect {
            described_class.create(:unknown)
          }.to raise_error(Mongoid::Errors::NoClientConfig)
        end
      end
    end

    context "when no name is provided" do

      let(:config) do
        { default: { hosts: ["127.0.0.1:27017"], database: database_id }}
      end

      before do
        Mongoid::Config.send(:clients=, config)
      end

      let(:client) do
        described_class.create
      end

      let(:cluster) do
        client.cluster
      end

      let(:seeds) do
        cluster.addresses.map{ |address| address.to_s }
      end

      it "returns the default client" do
        expect(client).to be_a(Mongo::Client)
      end

      it "sets the cluster's seeds" do
        expect(seeds).to eq([ "127.0.0.1:27017" ])
      end
    end

    context "when nil is provided and no default config" do

      let(:config) { nil }

      before do
        Mongoid.clients[:default] = nil
      end

      it "raises NoClientsConfig error" do
        expect{ Mongoid::Clients::Factory.create(config) }.to raise_error(Mongoid::Errors::NoClientsConfig)
      end
    end
  end

  describe ".default" do

    let(:config) do
      { default: { hosts: ["127.0.0.1:27017"], database: database_id }}
    end

    before do
      Mongoid::Config.send(:clients=, config)
    end

    let(:client) do
      described_class.default
    end

    let(:cluster) do
      client.cluster
    end

    let(:seeds) do
      cluster.addresses.map{ |address| address.to_s }
    end

    it "returns the default client" do
      expect(client).to be_a(Mongo::Client)
    end

    it "sets the cluster's seeds" do
      expect(seeds).to eq([ "127.0.0.1:27017" ])
    end
  end

  context "when options are provided with string keys" do

    let(:config) do
      {
        default: {
          hosts: [ "127.0.0.1:27017" ],
          database: database_id,
          options: {
            "server_selection_timeout" => 10,
            "write" => { "w" => 1 }
          }
        }
      }
    end

    before do
      Mongoid::Config.send(:clients=, config)
    end

    let(:client) do
      described_class.default
    end

    let(:cluster) do
      client.cluster
    end

    let(:seeds) do
      cluster.addresses.map{ |address| address.to_s }
    end

    it "returns the default client" do
      expect(client).to be_a(Mongo::Client)
    end

    it "sets the cluster's seeds" do
      expect(seeds).to eq([ "127.0.0.1:27017" ])
    end

    it "sets the server selection timeout" do
      expect(cluster.options[:server_selection_timeout]).to eq(10)
    end

    it "sets the write concern" do
      expect(client.write_concern).to be_a(Mongo::WriteConcern::Acknowledged)
    end
  end
end
