require "spec_helper"
require "rails/generators/mongoid/observer/observer_generator"

describe Mongoid::Generators::ObserverGenerator do

  destination File.expand_path("../../../../../../tmp", __FILE__)

  before do
    Rails.stubs(:application).returns(mock)
    prepare_destination
  end

  context "when no arguments are provided" do

    before do
      run_generator %w(company)
    end

    context "when generating a company observer" do

      let(:observer) do
        file("app/models/company_observer.rb")
      end

      it "generates the file" do
        observer.should exist
      end

      it "defines the observer subclass" do
        observer.should contain("class CompanyObserver < Mongoid::Observer")
      end
    end
  end
end
