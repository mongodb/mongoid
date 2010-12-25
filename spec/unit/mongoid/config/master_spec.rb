require "spec_helper"

describe Mongoid::Config::Master do

  after(:all) do
    Mongoid.master.connection.instance_variable_set(:@logger, nil)
  end

  # Note you will have to add a user to the database in order for these specs
  # to pass. From the mongo console you can do:
  #
  #   db.addUser("mongoid", "test");
  describe "#configure" do

    let(:master) do
      described_class.new(options)
    end

    let(:database) do
      master.configure
    end

    let(:connection) do
      database.connection
    end

    let(:node) do
      connection.nodes.first
    end

    context "when provided a uri" do

      context "when no pool size provided" do

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
          database.name.should == "mongoid_test"
        end

        it "defaults the pool size to 1" do
          connection.instance_variable_get(:@pool_size).should == 1
        end
      end

      context "when a pool size is provided" do

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
          database.name.should == "mongoid_test"
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
          database.name.should == "mongoid_test"
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
          database.name.should == "mongoid_test"
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

      context "when a username and password are provided" do

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
end
