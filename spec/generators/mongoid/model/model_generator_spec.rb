require 'spec_helper'

# Generators are not automatically loaded by Rails
require 'rails/generators/mongoid/model/model_generator'

module Rails
end
describe Mongoid::Generators::ModelGenerator do
  # Tell the generator where to put its output (what it thinks of as Rails.root)
  destination File.expand_path("../../../../../../tmp", __FILE__)

  before do
    Rails.stubs(:application).returns(mock)
    prepare_destination
  end

  describe 'for a company' do
    subject { file('app/models/company.rb') }

    describe 'defaults' do
      before do
        run_generator %w(company)
      end

      it { should exist }
      it { should contain "class Company" }
      it { should contain "include Mongoid::Document" }
    end
    describe 'with attributes' do
      before do
        run_generator %w(company name:string)
      end

      it { should contain "field :name, :type => String" }
    end
    describe 'with timestamps' do
      before do
        run_generator %w(company --timestamps)
      end

      it { should contain "include Mongoid::Timestamps" }
    end
    describe 'with a parent' do
      before do
        run_generator %w(company --parent organization)
      end

      it { should contain "class Company < Organization" }
      it { should_not contain "include Mongoid::Document" }
    end
    describe 'with versioning' do
      before do
        run_generator %w(company --versioning)
      end

      it { should contain "include Mongoid::Versioning" }
    end
  end

end
