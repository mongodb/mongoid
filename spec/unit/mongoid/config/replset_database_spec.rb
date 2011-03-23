require "spec_helper"

describe Mongoid::Config::ReplsetDatabase do

  describe "#configure" do

    subject do
      described_class.new(options)
    end

    let(:hosts) do
      [["localhost", 27010], ["localhost", 27010]]
    end

    let(:options) do
      { 'database' => 'mongoid_test', 'hosts' => hosts }
    end

    let(:replica_set) do
      described_class.new(options).configure
    end

    let(:repl_set_connection) do
      stub.quacks_like(Mongo::ReplSetConnection.allocate)
    end

    before do
      Mongo::ReplSetConnection.stubs(:new).returns(repl_set_connection)
    end

    it "should set a logger" do
      subject[:logger].should be_an_instance_of(Mongoid::Logger)
    end

    context "when authentication keys are not given" do

      it { should_not be_authenticating }

      it "should not add auth to connection" do
        repl_set_connection.expects(:add_auth).never
      end

      it "should not apply authentication" do
        repl_set_connection.expects(:apply_saved_authentication).never
      end
    end

    context "when authentication keys are given" do

      let(:options) do
        { 'database' => 'mongoid_test', 'username' => 'mongoid', 'password' => 'test', 'hosts' => hosts }
      end

      it { should be_authenticating }

      it "should add authentication and apply" do
        repl_set_connection.expects(:db)
        repl_set_connection.expects(:add_auth).with(options['database'], options['username'], options['password'])
        repl_set_connection.expects(:apply_saved_authentication)
        replica_set
      end
    end
  end
end
