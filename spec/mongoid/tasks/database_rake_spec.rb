# frozen_string_literal: true
# rubocop:todo all

require "rake"
require "spec_helper"
require "support/feature_sandbox"

shared_context "rake task" do
  let(:task_name) { self.class.top_level_description }
  let(:task) { Rake.application[task_name] }
  let(:task_file) { "mongoid/tasks/database" }

  let(:logger) do
    Logger.new(STDOUT, level: :error, formatter: ->(_sev, _dt, _prog, msg) { msg })
  end

  before do
    rake = Rake::Application.new
    Rake.application = rake
    rake.rake_require(task_file, $LOAD_PATH, [])
    Rake::Task.define_task(:environment)

    allow(Mongoid::Tasks::Database).to receive(:logger).and_return(logger)
  end

  shared_examples_for "create_indexes" do

    it "receives create_indexes" do
      expect(Mongoid::Tasks::Database).to receive(:create_indexes)
      task.invoke
    end
  end

  shared_examples_for 'create_search_indexes' do
    [ nil, *%w( 1 true yes on ) ].each do |truthy|
      context "when WAIT_FOR_SEARCH_INDEXES is #{truthy.inspect}" do
        local_env 'WAIT_FOR_SEARCH_INDEXES' => truthy

        it 'receives create_search_indexes with wait: true' do
          expect(Mongoid::Tasks::Database)
            .to receive(:create_search_indexes)
            .with(wait: true)
          task.invoke
        end
      end
    end

    %w( 0 false no off bogus ).each do |falsey|
      context "when WAIT_FOR_SEARCH_INDEXES is #{falsey.inspect}" do
        local_env 'WAIT_FOR_SEARCH_INDEXES' => falsey

        it 'receives create_search_indexes with wait: false' do
          expect(Mongoid::Tasks::Database)
            .to receive(:create_search_indexes)
            .with(wait: false)
          task.invoke
        end
      end
    end
  end

  shared_examples_for "create_collections" do

    it "receives create_collections" do
      expect(Mongoid::Tasks::Database).to receive(:create_collections)
      task.invoke
    end
  end

  shared_examples_for "force create_collections" do

    it "receives create_collections" do
      expect(Mongoid::Tasks::Database).to receive(:create_collections).with(force: true)
      task.invoke
    end
  end
end

shared_context "rails rake task" do
  let(:task_file) { "mongoid/railties/database" }

  around do |example|
    FeatureSandbox.quarantine do
      require "support/rails_mock"
      example.run
    end
  end
end

describe "db:drop" do
  include_context "rake task"
  include_context "rails rake task"

  it "calls mongoid:drop" do
    expect(task.prerequisites).to include("mongoid:drop")
  end

  it "works" do
    task.invoke
  end
end

describe "db:purge" do
  include_context "rake task"
  include_context "rails rake task"

  it "calls mongoid:drop" do
    expect(task.prerequisites).to include("mongoid:purge")
  end

  it "works" do
    task.invoke
  end
end

describe "db:seed" do
  include_context "rake task"
  include_context "rails rake task"

  it "calls environment" do
    expect(task.prerequisites).to include("environment")
  end

  it "works" do
    task.invoke
  end
end

describe "db:setup" do
  include_context "rake task"
  include_context "rails rake task"

  it "calls db:create" do
    expect(task.prerequisites).to include("db:create")
  end

  it "calls db:mongoid:create_indexes" do
    expect(task.prerequisites).to include("mongoid:create_indexes")
  end

  it "calls db:mongoid:create_collections" do
    expect(task.prerequisites).to include("mongoid:create_collections")
  end

  it "calls db:seed" do
    expect(task.prerequisites).to include("db:seed")
  end

  it_behaves_like "create_indexes"

  it "works" do
    expect(Mongoid::Tasks::Database).to receive(:create_indexes)
    expect(Mongoid::Tasks::Database).to receive(:create_collections)
    task.invoke
  end
end

describe "db:reset" do
  include_context "rake task"
  include_context "rails rake task"

  it "calls db:drop" do
    expect(task.prerequisites).to include("db:drop")
  end

  it "calls db:seed" do
    expect(task.prerequisites).to include("db:seed")
  end

  it "works" do
    task.invoke
  end
end

describe "db:create" do
  include_context "rake task"
  include_context "rails rake task"

  it "works" do
    task.invoke
  end
end

describe "db:migrate" do
  include_context "rake task"
  include_context "rails rake task"

  it "works" do
    task.invoke
  end
end

describe "db:test:prepare" do
  include_context "rake task"
  include_context "rails rake task"

  it_behaves_like "create_indexes"

  it "calls mongoid:create_indexes" do
    expect(task.prerequisites).to include("mongoid:create_indexes")
  end

  it "calls mongoid:create_collections" do
    expect(task.prerequisites).to include("mongoid:create_collections")
  end

  it "works" do
    expect(Mongoid::Tasks::Database).to receive(:create_indexes)
    expect(Mongoid::Tasks::Database).to receive(:create_collections)
    task.invoke
  end
end

describe "db:mongoid:create_indexes" do
  include_context "rake task"

  it_behaves_like "create_indexes"

  it "calls load_models" do
    expect(task.prerequisites).to include("load_models")
  end

  it "calls environment" do
    expect(task.prerequisites).to include("environment")
  end

  context "when using rails task" do
    include_context "rails rake task"

    it_behaves_like "create_indexes"
  end
end

describe 'db:mongoid:create_search_indexes' do
  include_context 'rake task'

  it_behaves_like 'create_search_indexes'

  it 'calls load_models' do
    expect(task.prerequisites).to include('load_models')
  end

  it 'calls environment' do
    expect(task.prerequisites).to include('environment')
  end

  context 'when using rails task' do
    include_context 'rails rake task'

    it_behaves_like 'create_search_indexes'
  end
end

describe "db:mongoid:create_collections" do
  include_context "rake task"

  it_behaves_like "create_collections"

  it "calls load_models" do
    expect(task.prerequisites).to include("load_models")
  end

  it "calls environment" do
    expect(task.prerequisites).to include("environment")
  end

  context "when using rails task" do
    include_context "rails rake task"

    it_behaves_like "create_collections"
  end
end

describe "db:mongoid:create_collections:force" do
  include_context "rake task"

  it_behaves_like "force create_collections"

  it "calls load_models" do
    expect(task.prerequisites).to include("load_models")
  end

  it "calls environment" do
    expect(task.prerequisites).to include("environment")
  end

  context "when using rails task" do
    include_context "rails rake task"

    it_behaves_like "force create_collections"
  end
end

describe "db:mongoid:remove_undefined_indexes" do
  include_context "rake task"

  it "receives remove_undefined_indexes" do
    expect(Mongoid::Tasks::Database).to receive(:remove_undefined_indexes)
    task.invoke
  end

  it "calls environment" do
    expect(task.prerequisites).to include("environment")
  end

  context "when using rails task" do
    include_context "rails rake task"

    it "receives remove_undefined_indexes" do
      expect(Mongoid::Tasks::Database).to receive(:remove_undefined_indexes)
      task.invoke
    end
  end
end

describe "db:mongoid:remove_indexes" do
  include_context "rake task"

  it "receives remove_indexes" do
    expect(Mongoid::Tasks::Database).to receive(:remove_indexes)
    task.invoke
  end

  it "calls environment" do
    expect(task.prerequisites).to include("environment")
  end

  context "when using rails task" do
    include_context "rails rake task"

    it "receives remove_indexes" do
      expect(Mongoid::Tasks::Database).to receive(:remove_indexes)
      task.invoke
    end
  end
end

describe 'db:mongoid:remove_search_indexes' do
  include_context 'rake task'

  it 'receives remove_search_indexes' do
    expect(Mongoid::Tasks::Database).to receive(:remove_search_indexes)
    task.invoke
  end

  it 'calls environment' do
    expect(task.prerequisites).to include('environment')
  end

  context 'when using rails task' do
    include_context 'rails rake task'

    it 'receives remove_search_indexes' do
      expect(Mongoid::Tasks::Database).to receive(:remove_search_indexes)
      task.invoke
    end
  end
end

describe "db:mongoid:drop" do
  include_context "rake task"

  it "works" do
    task.invoke
  end

  context "when using rails task" do
    include_context "rails rake task"

    it "works" do
      task.invoke
    end
  end
end

describe "db:mongoid:purge" do
  include_context "rake task"

  it "receives a purge" do
    expect(Mongoid).to receive(:purge!)
    task.invoke
  end

  context "when using rails task" do
    include_context "rails rake task"

    it "receives a purge" do
      expect(Mongoid).to receive(:purge!)
      task.invoke
    end
  end
end

describe "db:mongoid:encryption:create_data_key" do
  require_enterprise
  require_libmongocrypt
  include_context 'with encryption'
  restore_config_clients
  include_context "rake task"

  let(:task_file) { "mongoid/tasks/encryption" }

  let(:config) do
    {
      default: {
        hosts: SpecConfig.instance.addresses,
        database: database_id,
        options: {
          auto_encryption_options: {
            kms_providers: kms_providers,
            key_vault_namespace: key_vault_namespace,
            extra_options: extra_options
          }
        }
      }
    }
  end

  before do
    Mongoid::Config.send(:clients=, config)

    expect_any_instance_of(Mongo::ClientEncryption)
      .to receive(:create_data_key)
      .with('local', {})
      .and_call_original
  end

  it "creates the key" do
    task.invoke
  end

  context "when using rails task" do
    include_context "rails rake task"

    it "creates the key" do
      task.invoke
    end
  end
end
