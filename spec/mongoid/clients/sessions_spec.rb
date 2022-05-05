# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Clients::Sessions do

  before(:all) do
    CONFIG[:clients][:other] = CONFIG[:clients][:default].dup
    CONFIG[:clients][:other][:database] = 'other'
    Mongoid::Clients.clients.values.each(&:close)
    Mongoid::Config.send(:clients=, CONFIG[:clients])
    Mongoid::Clients.with_name(:other).subscribe(Mongo::Monitoring::COMMAND, EventSubscriber.new)
  end

  after(:all) do
    Mongoid::Clients.with_name(:other).close
    Mongoid::Clients.clients.delete(:other)
  end

  let(:subscriber) do
    client = Mongoid::Clients.with_name(:other)
    monitoring = client.send(:monitoring)
    monitoring.subscribers['Command'].find do |s|
      s.is_a?(EventSubscriber)
    end
  end

  let(:insert_events) do
    # Driver 2.5 sends command_name as a symbol
    subscriber.started_events.select { |event| event.command_name.to_s == 'insert' }
  end

  let(:update_events) do
    # Driver 2.5 sends command_name as a symbol
    subscriber.started_events.select { |event| event.command_name.to_s == 'update' }
  end

  context 'when a session is used on a model class' do

    context 'when sessions are supported' do
      min_server_version '3.6'

      around do |example|
        Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
        subscriber.clear_events!
        Person.with(client: :other) do
          example.run
        end
        Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
      end

      context 'when another thread is started' do

        let!(:last_use_diff) do
          Person.with_session do |session|
            Person.create!
            Person.create!
            last_use = session.instance_variable_get(:@server_session).last_use
            Thread.new { Person.create! }.value
            session.instance_variable_get(:@server_session).last_use - last_use
          end
        end

        it 'does not use the session for that thread' do
          expect(Person.count).to be(2)
          expect(Person.with(client: :default) { Person.count }).to be(1)
          lsids_sent = insert_events.collect { |event| event.command['lsid'] }
          expect(lsids_sent.size).to eq(2)
          expect(lsids_sent.uniq.size).to eq(1)
          expect(last_use_diff).to eq(0)
        end
      end

      context 'when the operations in the session block are all on the class' do

        before do
          Person.with_session do
            Person.create!
            Person.create!
          end
        end

        it 'uses a single session id for all operations on the class' do
          expect(Person.count).to be(2)
          lsids_sent = insert_events.collect { |event| event.command['lsid'] }
          expect(lsids_sent.size).to eq(2)
          expect(lsids_sent.uniq.size).to eq(1)
        end
      end

      context 'when the operations in the session block are also on another class' do

        context 'when the other class uses the same client' do

          before do
            Post.with(client: :other) do
              Person.with_session do
                Person.create!
                Person.create!
                Post.create!
              end
            end
          end

          it 'uses a single session id for all operations on the class' do
            expect(Post.with(client: :other) { |klass| klass.count }).to be(1)
            lsids_sent = insert_events.collect { |event| event.command['lsid'] }
            expect(lsids_sent.size).to eq(3)
            expect(lsids_sent.uniq.size).to eq(1)
          end
        end

        context 'when the other class uses a different client' do

          let!(:error) do
            e = nil
            begin
              Person.with_session do
                Person.create!
                Person.create!
                Post.create!
              end
            rescue => ex
                e = ex
            end
            e
          end

          it 'raises an error' do
            expect(error).to be_a(Mongoid::Errors::InvalidSessionUse)
          end

          it 'uses a single session id for all operations on the class' do
            expect(Person.count).to be(2)
            lsids_sent = insert_events.collect { |event| event.command['lsid'] }
            expect(lsids_sent.size).to eq(2)
            expect(lsids_sent.uniq.size).to eq(1)
          end
        end

        context 'when sessions are nested' do

          let!(:error) do
            e = nil
            begin
              Person.with_session do
                Person.with_session do
                  Person.create!
                  Post.create!
                end
              end
            rescue => ex
              e = ex
            end
            e
          end

          it 'raises an error' do
            expect(error).to be_a(Mongoid::Errors::InvalidSessionUse)
          end

          it 'does not execute any operations' do
            expect(Person.count).to be(0)
            expect(insert_events).to be_empty
          end
        end
      end
    end
  end

  context 'when a session is used on a model instance' do

    let!(:person) do
      Person.with(client: :other) do |klass|
        klass.create!
      end
    end

    context 'when sessions are supported' do
      min_server_version '3.6'

      around do |example|
        Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
        subscriber.clear_events!
        person.with(client: :other) do
          example.run
        end
        Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
      end

      context 'when the operations in the session block are all on the instance' do

        before do
          person.with_session do
            person.username = 'Emily'
            person.save!
            person.age = 80
            person.save!
          end
        end

        it 'uses a single session id for all operations on the class' do
          expect(person.reload.username).to eq('Emily')
          expect(person.reload.age).to eq(80)
          lsids_sent = update_events.collect { |event| event.command['lsid'] }
          expect(lsids_sent.size).to eq(2)
          expect(lsids_sent.uniq.size).to eq(1)
        end
      end

      context 'when the operations in the session block are also on another class' do

        context 'when the other class uses the same client' do

          before do
            Post.with(client: :other) do
              person.with_session do
                person.username = 'Emily'
                person.save!
                person.posts << Post.create!
              end
            end
          end

          it 'uses a single session id for all operations on the class' do
            expect(person.reload.username).to eq('Emily')
            expect(Post.with(client: :other) { Post.count }).to be(1)
            update_lsids_sent = update_events.collect { |event| event.command['lsid'] }
            expect(update_lsids_sent.size).to eq(3) # person update, counter cache, post assignment
            expect(update_lsids_sent.uniq.size).to eq(1) # person update, counter cache, post assignment
            insert_lsids_sent = insert_events.collect { |event| event.command['lsid'] }
            expect(insert_lsids_sent.size).to eq(2)
            expect(insert_lsids_sent.uniq.size).to eq(1)
            expect(update_lsids_sent.uniq).to eq(insert_lsids_sent.uniq)
          end
        end

        context 'when the other class uses a different client' do

          let!(:error) do
            e = nil
            begin
              person.with_session do
                person.username = 'Emily'
                person.save!
                person.posts << Post.create!
              end
            rescue => ex
              e = ex
            end
            e
          end

          it 'raises an error' do
            expect(error).to be_a(Mongoid::Errors::InvalidSessionUse)
          end

          it 'uses a single session id for all operations on the class' do
            expect(person.reload.username).to eq('Emily')
            expect(Post.count).to be(0)
            update_lsids_sent = update_events.collect { |event| event.command['lsid'] }
            expect(update_lsids_sent.size).to eq(1)
          end
        end

        context 'when sessions are nested' do

          let!(:error) do
            e = nil
            begin
              person.with_session do
                person.with_session do
                  person.username = 'Emily'
                  person.save!
                  person.posts << Post.create!
                end
              end
            rescue => ex
              e = ex
            end
            e
          end

          it 'raises an error' do
            expect(error).to be_a(Mongoid::Errors::InvalidSessionUse)
          end

          it 'does not execute any operations' do
            expect(person.reload.username).not_to eq('Emily')
            expect(Post.count).to be(0)
            expect(update_events).to be_empty
          end
        end
      end
    end
  end
end
