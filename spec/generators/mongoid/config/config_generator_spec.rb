require 'spec_helper'

# Generators are not automatically loaded by Rails
require 'rails/generators/mongoid/config/config_generator'

module Rails
  class Application
  end
end
module MyApp
  class Application < Rails::Application
  end
end

describe Mongoid::Generators::ConfigGenerator do
  # Tell the generator where to put its output (what it thinks of as Rails.root)
  destination File.expand_path("../../../../../../tmp", __FILE__)


  before do
    prepare_destination
  end

  describe 'no arguments' do
    before { run_generator  }

    describe 'config/mongoid.yml' do
      subject { file('config/mongoid.yml') }
      it { should exist }
      it { should contain "database: my_app_development" }
    end
  end

  describe 'specifying database name' do
    before { run_generator %w(my_database) }

    describe 'config/mongoid.yml' do
      subject { file('config/mongoid.yml') }
      it { should exist }
      it { should contain "database: my_database_development" }
    end
  end
end
