# frozen_string_literal: true
# rubocop:todo all

require 'spec_helper'

describe 'distinct on aliased fields' do

  let(:client) { Person.collection.client }

  let(:subscriber) do
    Mrss::EventSubscriber.new
  end

  before do
    client.subscribe(Mongo::Monitoring::COMMAND, subscriber)
  end

  after do
    client.unsubscribe(Mongo::Monitoring::COMMAND, subscriber)
  end

  let(:event) do
    subscriber.single_command_started_event('distinct')
  end

  let(:command) { event.command }

  context 'top level field' do
    let(:query) do
      Person.distinct(:test)
    end

    it 'expands the alias' do
      query

      command['key'].should == 't'
    end
  end

  context 'embedded document field' do
    let(:query) do
      Person.distinct('phone_numbers.extension')
    end

    it 'expands the alias' do
      query

      command['key'].should == 'phone_numbers.ext'
    end
  end
end

describe 'pluck on aliased fields' do

  let(:client) { Person.collection.client }

  let(:subscriber) do
    Mrss::EventSubscriber.new
  end

  before do
    client.subscribe(Mongo::Monitoring::COMMAND, subscriber)
  end

  after do
    client.unsubscribe(Mongo::Monitoring::COMMAND, subscriber)
  end

  let(:event) do
    subscriber.single_command_started_event('find')
  end

  let(:command) { event.command }

  context 'top level field' do
    let(:query) do
      Person.pluck(:test)
    end

    it 'expands the alias' do
      query

      command['projection'].should == {'t' => true}
    end
  end

  context 'embedded document field' do
    let(:query) do
      Person.pluck('phone_numbers.extension')
    end

    it 'expands the alias' do
      query

      command['projection'].should == {'phone_numbers.ext' => true}
    end
  end
end
