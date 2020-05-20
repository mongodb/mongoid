# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe Mongoid::Document do
  context 'when including class uses delegate' do
    let(:patient) do
      DelegatingPatient.new(
        email: Email.new(address: 'test@example.com'),
      )
    end

    it 'works for instance level delegation' do
      patient.address.should == 'test@example.com'
    end

    it 'works for class level delegation' do
      DelegatingPatient.default_client.should be Mongoid.default_client
    end
  end
end
