require 'spec_helper'

# Generators are not automatically loaded by Rails
require 'rails/generators/mongoid/config/config_generator'

describe Mongoid::Generators::ConfigGenerator do

  module Rails
    class Application
    end
  end

  module MyApp
    class Application < Rails::Application
    end
  end

  # Tell the generator where to put its output (what it thinks of as Rails.root)
  destination File.expand_path("../../../../../../tmp", __FILE__)

  before do
    prepare_destination
  end

  describe 'no arguments' do
    before do
      run_generator
    end

    describe 'config/mongoid.yml' do
      subject { file('config/mongoid.yml') }
      it { should exist }
      it { should contain "database: my_app_development" }
    end
  end

  describe 'specifying database name' do
    before do
      run_generator %w(my_database)
    end

    describe 'config/mongoid.yml' do
      subject { file('config/mongoid.yml') }
      it { should exist }
      it { should contain "database: my_database_development" }
    end
  end
end
