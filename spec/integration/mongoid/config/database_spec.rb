require "spec_helper"

describe Mongoid::Config::Database do

  describe "#configure" do

    context "when configuring a master instance" do

      let(:config) do
        described_class.new(options)
      end

      let(:master) do
        config.configure.first
      end

      let(:connection) do
        master.connection
      end

      let(:node) do
        connection.primary
      end

      context "when provided a uri" do

        context "when the uri is on mongohq", :config => :mongohq do

          let(:mongohq_user) do
            ENV["MONGOHQ_USER_MONGOID"]
          end

          let(:mongohq_password) do
            ENV["MONGOHQ_PASSWORD_MONGOID"]
          end

          let(:options) do
            {
              "uri" =>
              "mongodb://#{mongohq_user}:#{mongohq_password}@flame.mongohq.com:27040/mongoid"
            }
          end

          it "connects to the proper host" do
            node[0].should == "flame.mongohq.com"
          end

          it "connects to the proper port" do
            node[1].should == 27040
          end
        end

        context "when no pool size provided", :config => :user do

          let(:options) do
            { "uri" => "mongodb://mongoid:test@localhost:27017/mongoid_test" }
          end

          it "sets the node host to the uri host" do
            node[0].should == "localhost"
          end

          it "sets the node port to the uri port" do
            node[1].should == 27017
          end

          it "sets the database name to the uri database name" do
            master.name.should == "mongoid_test"
          end

          it "defaults the pool size to 1" do
            connection.instance_variable_get(:@pool_size).should == 1
          end
        end

        context "when a pool size is provided", :config => :user do

          let(:options) do
            {
              "uri" => "mongodb://mongoid:test@localhost:27017/mongoid_test",
              "pool_size" => 2
            }
          end

          it "sets the node host to the uri host" do
            node[0].should == "localhost"
          end

          it "sets the node port to the uri port" do
            node[1].should == 27017
          end

          it "sets the database name to the uri database name" do
            master.name.should == "mongoid_test"
          end

          it "sets the pool size" do
            connection.instance_variable_get(:@pool_size).should == 2
          end

          it "sets the logger to the mongoid logger" do
            connection.logger.should be_a(Mongoid::Logger)
          end
        end
      end

      context "when no uri provided" do

        context "when a host is provided" do

          let(:options) do
            { "host" => "localhost", "database" => "mongoid_test" }
          end

          it "sets the node host to the uri host" do
            node[0].should == "localhost"
          end

          it "sets the node port to the uri port" do
            node[1].should == 27017
          end

          it "sets the database name to the uri database name" do
            master.name.should == "mongoid_test"
          end

          it "sets the pool size to 1" do
            connection.instance_variable_get(:@pool_size).should == 1
          end
        end

        context "when no host is provided" do

          let(:options) do
            { "database" => "mongoid_test", "port" => 27017 }
          end

          it "sets the node host to localhost" do
            node[0].should == "localhost"
          end

          it "sets the node port to the uri port" do
            node[1].should == 27017
          end

          it "sets the database name to the uri database name" do
            master.name.should == "mongoid_test"
          end
        end

        context "when a port is provided" do

          let(:options) do
            { "database" => "mongoid_test", "port" => 27017 }
          end

          it "sets the node host to localhost" do
            node[0].should == "localhost"
          end

          it "sets the node port to the uri port" do
            node[1].should == 27017
          end
        end

        context "when no port is provided" do

          let(:options) do
            { "database" => "mongoid_test" }
          end

          it "sets the node host to localhost" do
            node[0].should == "localhost"
          end

          it "sets the node port to the uri port" do
            node[1].should == 27017
          end
        end

        context "when a username and password are provided", :config => :user do

          let(:options) do
            {
              "database" => "mongoid_test",
              "username" => "mongoid",
              "password" => "test"
            }
          end

          it "sets the node host to localhost" do
            node[0].should == "localhost"
          end

          it "sets the node port to the uri port" do
            node[1].should == 27017
          end
        end
      end
    end

    context "when configuring a slave instances", :config => :slaves do

      let(:config) do
        described_class.new(options)
      end

      let(:slaves) do
        config.configure.last
      end

      let(:connection_one) do
        slaves.first.connection
      end

      let(:connection_two) do
        slaves.last.connection
      end

      let(:node_one) do
        connection_one.primary
      end

      let(:node_two) do
        connection_two.primary
      end

      context "when provided a uri" do

        context "when no pool size provided" do

          let(:options) do
            {
              "database" => "mongoid_test",
              "uri" => "mongodb://localhost:27017",
              "slaves" => [
                { "uri" => "mongodb://localhost:27018" },
                { "uri" => "mongodb://localhost:27019" }
              ]
            }
          end

          it "sets the first node host to the uri host" do
            node_one[0].should == "localhost"
          end

          it "sets the first node port to the uri port" do
            node_one[1].should == 27018
          end

          it "sets the first database name to the uri database name" do
            slaves[0].name.should == "mongoid_test"
          end

          it "defaults the first pool size to 1" do
            connection_one.instance_variable_get(:@pool_size).should == 1
          end

          it "sets the second node host to the uri host" do
            node_two[0].should == "localhost"
          end

          it "sets the second node port to the uri port" do
            node_two[1].should == 27019
          end

          it "sets the second database name to the uri database name" do
            slaves[1].name.should == "mongoid_test"
          end

          it "defaults the second pool size to 1" do
            connection_two.instance_variable_get(:@pool_size).should == 1
          end
        end

        context "when a pool size is provided" do

          let(:options) do
            {
              "database" => "mongoid_test",
              "pool_size" => 2,
              "uri" => "mongodb://localhost:27017",
              "slaves" => [
                { "uri" => "mongodb://localhost:27018" },
                { "uri" => "mongodb://localhost:27019" }
              ]
            }
          end

          it "sets the first pool size" do
            connection_one.instance_variable_get(:@pool_size).should == 2
          end

          it "sets the second pool size" do
            connection_two.instance_variable_get(:@pool_size).should == 2
          end
        end
      end

      context "when no uri provided" do

        context "when hosts are provided" do

          let(:options) do
            {
              "host" => "localhost",
              "database" => "mongoid_test",
              "slaves" => [
                { "host" => "localhost", "port" => 27018 },
                { "host" => "localhost", "port" => 27019 }
              ]
            }
          end

          it "sets the first node host to the firsts host" do
            node_one[0].should == "localhost"
          end

          it "sets the first node port to the first port" do
            node_one[1].should == 27018
          end

          it "sets the first database name to the database name" do
            slaves[0].name.should == "mongoid_test"
          end

          it "defaults the first pool size to 1" do
            connection_one.instance_variable_get(:@pool_size).should == 1
          end

          it "sets the second node host to the second host" do
            node_two[0].should == "localhost"
          end

          it "sets the second node port to the second port" do
            node_two[1].should == 27019
          end

          it "sets the second database name to the database name" do
            slaves[1].name.should == "mongoid_test"
          end

          it "defaults the second pool size to 1" do
            connection_two.instance_variable_get(:@pool_size).should == 1
          end
        end

        context "when no host is provided" do

          let(:options) do
            { "database" => "mongoid_test", "port" => 27017,
              "slaves" => [
                { "port" => 27018 },
                { "port" => 27019 }
              ]
            }
          end

          it "sets the first node host to localhost" do
            node_one[0].should == "localhost"
          end

          it "sets the second node host to localhost" do
            node_two[0].should == "localhost"
          end
        end

        context "when a username and password are provided" do

          let(:options) do
            {
              "database" => "mongoid_test",
              "username" => "mongoid",
              "password" => "test",
              "slaves" => [
                { "port" => 27018 },
                { "port" => 27019 }
              ]
            }
          end

          it "sets the first node host to localhost" do
            node_one[0].should == "localhost"
          end

          it "sets the second node port to the uri port" do
            node_two[0].should == "localhost"
          end
        end
      end
    end
  end
end
