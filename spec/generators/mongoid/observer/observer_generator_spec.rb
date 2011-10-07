require 'spec_helper'

# Generators are not automatically loaded by Rails
require 'rails/generators/mongoid/observer/observer_generator'

module Rails
end
describe Mongoid::Generators::ObserverGenerator do
  # Tell the generator where to put its output (what it thinks of as Rails.root)
  destination File.expand_path("../../../../../../tmp", __FILE__)

  before do
    Rails.stubs(:application).returns(mock)
    prepare_destination
  end

  describe 'no arguments' do
    before { run_generator %w(company) }

    describe 'app/models/company_observer.rb' do
      subject { file('app/models/company_observer.rb') }
      it { should exist }
      it { should contain "class CompanyObserver < Mongoid::Observer" }
    end
  end
end
