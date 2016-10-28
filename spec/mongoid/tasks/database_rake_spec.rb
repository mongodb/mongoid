require "rake"
require "spec_helper"

unless defined?(Rails)
  module Rails
  end
end

shared_context "rake task" do
  let(:task_name) { self.class.top_level_description }
  let(:task) { Rake.application[task_name] }
  let(:task_file) { "mongoid/tasks/database" }

  let(:logger) do
    double("logger").tap do |log|
      allow(log).to receive(:info)
    end
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
end

shared_context "rails rake task" do
  let(:task_file) { "mongoid/railties/database" }

  let(:application) do
    app = double("application")
    allow(app).to receive(:eager_load!)
    app
  end
end

describe "db:drop", if: non_legacy_server? do
  include_context "rake task"
  include_context "rails rake task"

  it "calls mongoid:drop" do
    expect(task.prerequisites).to include("mongoid:drop")
  end

  it "works" do
    task.invoke
  end
end

describe "db:purge", if: non_legacy_server? do
  include_context "rake task"
  include_context "rails rake task"

  it "calls mongoid:drop" do
    expect(task.prerequisites).to include("mongoid:purge")
  end

  it "works" do
    task.invoke
  end
end

describe "db:seed", if: non_legacy_server? do
  include_context "rake task"
  include_context "rails rake task"

  it "calls environment" do
    expect(task.prerequisites).to include("environment")
  end

  it "works" do
    expect(Rails).to receive(:root).and_return(".")
    task.invoke
  end
end

describe "db:setup", if: non_legacy_server? do
  include_context "rake task"
  include_context "rails rake task"

  it "calls db:create" do
    expect(task.prerequisites).to include("db:create")
  end

  it "calls db:mongoid:create_indexes" do
    expect(task.prerequisites).to include("mongoid:create_indexes")
  end

  it "calls db:seed" do
    expect(task.prerequisites).to include("db:seed")
  end

  it_behaves_like "create_indexes" do

    before do
      expect(Rails).to receive(:root).and_return(".")
      expect(Rails).to receive(:application).and_return(application)
    end
  end

  it "works" do
    expect(Mongoid::Tasks::Database).to receive(:create_indexes)
    expect(Rails).to receive(:root).and_return(".")
    expect(Rails).to receive(:application).and_return(application)
    task.invoke
  end
end

describe "db:reset", if: non_legacy_server? do
  include_context "rake task"
  include_context "rails rake task"

  it "calls db:drop" do
    expect(task.prerequisites).to include("db:drop")
  end

  it "calls db:seed" do
    expect(task.prerequisites).to include("db:seed")
  end

  it "works" do
    expect(Rails).to receive(:root).and_return(".")
    task.invoke
  end
end

describe "db:create", if: non_legacy_server? do
  include_context "rake task"
  include_context "rails rake task"

  it "works" do
    task.invoke
  end
end

describe "db:migrate", if: non_legacy_server? do
  include_context "rake task"
  include_context "rails rake task"

  it "works" do
    task.invoke
  end
end

describe "db:test:prepare", if: non_legacy_server? do
  include_context "rake task"
  include_context "rails rake task"

  it_behaves_like "create_indexes" do
    before do
      expect(Rails).to receive(:application).and_return(application)
    end
  end

  it "calls mongoid:create_indexes" do
    expect(task.prerequisites).to include("mongoid:create_indexes")
  end

  it "works" do
    expect(Rails).to receive(:application).and_return(application)
    expect(Mongoid::Tasks::Database).to receive(:create_indexes)
    task.invoke
  end
end

describe "db:mongoid:create_indexes", if: non_legacy_server? do
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

    before do
      expect(Rails).to receive(:application).and_return(application)
    end

    it_behaves_like "create_indexes"
  end
end

describe "db:mongoid:remove_undefined_indexes", if: non_legacy_server? do
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

    before do
      expect(Rails).to receive(:application).and_return(application)
    end

    it "receives remove_undefined_indexes" do
      expect(Mongoid::Tasks::Database).to receive(:remove_undefined_indexes)
      task.invoke
    end
  end
end

describe "db:mongoid:remove_indexes", if: non_legacy_server? do
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

    before do
      expect(Rails).to receive(:application).and_return(application)
    end

    it "receives remove_indexes" do
      expect(Mongoid::Tasks::Database).to receive(:remove_indexes)
      task.invoke
    end
  end
end

describe "db:mongoid:drop", if: non_legacy_server? do
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

describe "db:mongoid:purge", if: non_legacy_server? do
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
