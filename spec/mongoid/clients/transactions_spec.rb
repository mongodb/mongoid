# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Clients::Sessions do
  before(:all) do
    if Gem::Version.new(Mongo::VERSION) < Gem::Version.new('2.6')
      skip 'Driver does not support transactions'
    end
  end

  before(:all) do
    if Gem::Version.new(Mongo::VERSION) >= Gem::Version.new('2.6')
      CONFIG[:clients][:other] = CONFIG[:clients][:default].dup
      CONFIG[:clients][:other][:database] = 'other'
      Mongoid::Clients.clients.values.each(&:close)
      Mongoid::Config.send(:clients=, CONFIG[:clients])
      Mongoid::Clients.with_name(:other).subscribe(Mongo::Monitoring::COMMAND, EventSubscriber.new)
    end
  end

  after(:all) do
    if Gem::Version.new(Mongo::VERSION) >= Gem::Version.new('2.6')
      Mongoid::Clients.with_name(:other).close
      Mongoid::Clients.clients.delete(:other)
    end
  end

  let(:subscriber) do
    Mongoid::Clients.with_name(:other).send(:monitoring).subscribers['Command'].find do |s|
      s.is_a?(EventSubscriber)
    end
  end

  let(:insert_events) do
    subscriber.started_events.select { |event| event.command_name == 'insert' }
  end

  let(:insert_events_txn_numbers) do
    insert_events.map { |i| i.instance_variable_get(:@integer) }
  end

  let(:update_events) do
    subscriber.started_events.select { |event| event.command_name == 'update' }
  end

  let(:update_events_txn_numbers) do
    update_events.map { |i| i.instance_variable_get(:@integer) }
  end

  let(:other_events) do
    subscriber.started_events.reject { |event| ['insert', 'update'].include?(event.command_name) }
  end

  context 'when a transaction is used on a model class' do

    context 'when transactions are supported' do
      require_transaction_support

      around do |example|
        Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
        Mongoid::Clients.with_name(:other).command(create: :people)
        Mongoid::Clients.with_name(:other).command(create: :posts)
        Mongoid::Clients.with_name(:other).command(create: :canvases)
        subscriber.clear_events!
        Canvas.with(client: :other) do
          Person.with(client: :other) do
            example.run
          end
        end
        Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
      end

      context 'when another thread is started' do

        let!(:last_use_diff) do
          Person.with_session do |s|
            s.start_transaction
            Person.create!
            Person.create!
            Thread.new { Person.create! }.value
            s.commit_transaction
          end
        end

        it 'does not use the transaction for that thread' do
          expect(Person.count).to be(2)
          expect(Person.with(client: :default) { Person.count }).to be(1)
          expect(insert_events.count { |e| e.command['startTransaction'] }).to be(1)
          expect(other_events.count { |e| e.command_name == 'commitTransaction' }).to be(1)
        end
      end

      context 'when the operations in the transactions block are all on the class' do

        before do
          Person.with_session do |s|
            s.start_transaction
            Person.create!
            Person.create!
            s.commit_transaction
          end
        end

        it 'uses a single transaction number for all operations on the class' do
          expect(Person.count).to be(2)
          expect(insert_events_txn_numbers.size).to eq(2)
          expect(insert_events_txn_numbers.uniq.size).to eq(1)
        end
      end

      context 'when the operations in the transactions block are also on another class' do

        context 'when the other class uses the same client' do

          before do
            Post.with(client: :other) do
              Person.with_session do |s|
                s.start_transaction
                Person.create!
                Person.create!
                Post.create!
                s.commit_transaction
              end
            end
          end

          it 'uses a single transaction number for all operations on the class' do
            expect(Post.with(client: :other) { |klass| klass.count }).to be(1)
            expect(insert_events_txn_numbers.size).to eq(3)
            expect(insert_events_txn_numbers.uniq.size).to eq(1)
          end
        end

        context 'when the other class uses a different client' do

          let!(:error) do
            e = nil
            begin
              Person.with_session do |s|
                s.start_transaction
                Person.create!
                Person.create!
                Post.create!
                s.commit_transaction
              end
            rescue => ex
                e = ex
            end
            e
          end

          it 'raises an error' do
            expect(error).to be_a(Mongoid::Errors::InvalidSessionUse)
          end

          it 'aborted the transaction' do
            expect(Person.count).to be(0)
            expect(Post.count).to be(0)
            expect(insert_events_txn_numbers.size).to eq(2)
            expect(other_events.count { |e| e.command_name == 'abortTransaction'}).to be(1)
            expect(other_events.count { |e| e.command_name == 'commitTransaction'}).to be(0)
          end
        end

        context 'when transactions are nested' do

          let!(:error) do
            e = nil
            begin
              Person.with_session do |s|
                s.start_transaction
                s.start_transaction
                Person.create!
                Post.create!
                s.commit_transaction
              end
            rescue => ex
              e = ex
            end
            e
          end

          it 'raises an error' do
            expect(error).to be_a(Mongo::Error::InvalidTransactionOperation)
          end

          it 'does not execute any operations' do
            expect(Person.count).to be(0)
            expect(Post.count).to be(0)
            expect(insert_events).to be_empty
          end
        end
      end

      context 'When reloading an embedded document created inside a transaction' do
        it 'does not raise an error and has the correct document' do
          Canvas.with_session do |s|
            s.start_transaction

            p = Palette.new
            c = Canvas.new(palette: p)
            c.save!

            expect do
              p.reload
            end.to_not raise_error

            expect(c.palette).to eq(p)

            s.commit_transaction
          end
        end
      end
    end

    context 'when sessions are supported but transactions are not' do
      min_server_version '3.6'
      # Could also test 4.0 in sharded cluster
      max_server_version '3.6'

      let!(:error) do
        e = nil
        begin
          Person.with_session do |s|
            s.start_transaction
            Person.create!
            s.commit_transaction
          end
        rescue => ex
          e = ex
        end
        e
      end

      it 'raises a transactions not supported error' do
        expect(Person.count).to eq(0)
        expect(error).to be_a(Mongo::Error::OperationFailure)
      end
    end
  end

  context 'when a transaction is used on a model instance' do

    let!(:person) do
      Person.with(client: :other) do |klass|
        klass.create!
      end
    end

    context 'when transactions are supported' do
      require_transaction_support

      around do |example|
        Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
        Mongoid::Clients.with_name(:other).command(create: :people)
        Mongoid::Clients.with_name(:other).command(create: :posts)
        subscriber.clear_events!
        person.with(client: :other) do
          example.run
        end
        Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
      end

      context 'when the operations in the transaction block are all on the instance' do

        before do
          person.with_session do |s|
            s.start_transaction
            person.username = 'Emily'
            person.save!
            person.age = 80
            person.save!
            s.commit_transaction
          end
        end

        it 'uses a single transaction number for all operations on the class' do
          expect(person.reload.username).to eq('Emily')
          expect(person.reload.age).to eq(80)
          expect(update_events_txn_numbers.size).to eq(2)
          expect(update_events_txn_numbers.uniq.size).to eq(1)
        end
      end

      context 'when the operations in the transaction block are also on another class' do

        context 'when the other class uses the same client' do

          before do
            Post.with(client: :other) do
              person.with_session do |s|
                s.start_transaction
                person.username = 'Emily'
                person.save!
                person.posts << Post.create!
                s.commit_transaction
              end
            end
          end

          it 'uses a single transaction number for all operations on the class' do
            expect(person.reload.username).to eq('Emily')
            expect(Post.with(client: :other) { Post.count }).to be(1)
            expect(update_events_txn_numbers.size).to eq(3) # person update, counter cache, post assignment
            expect(update_events_txn_numbers.uniq.size).to eq(1) # person update, counter cache, post assignment
            expect(insert_events_txn_numbers.size).to eq(2)
            expect(insert_events_txn_numbers.uniq.size).to eq(1)
            expect(update_events_txn_numbers.uniq).to eq(insert_events_txn_numbers.uniq)
          end
        end

        context 'when the other class uses a different client' do

          let!(:error) do
            e = nil
            begin
              person.with_session do |s|
                s.start_transaction
                person.username = 'Emily'
                person.save!
                person.posts << Post.create!
                s.commit_transaction
              end
            rescue => ex
              e = ex
            end
            e
          end

          it 'raises an error' do
            expect(error).to be_a(Mongoid::Errors::InvalidSessionUse)
          end

          it 'aborted the transction' do
            expect(person.reload.username).not_to eq('Emily')
            expect(Post.count).to be(0)
            expect(update_events_txn_numbers.size).to eq(1)
            expect(insert_events_txn_numbers.size).to eq(1)
          end
        end

        context 'when transactions are nested' do

          let!(:error) do
            e = nil
            begin
              person.with_session do |s|
                s.start_transaction
                s.start_transaction
                person.username = 'Emily'
                person.save!
                person.posts << Post.create!
                s.commit_transaction
              end
            rescue => ex
              e = ex
            end
            e
          end

          it 'raises an error' do
            expect(error).to be_a(Mongo::Error::InvalidTransactionOperation)
          end

          it 'does not execute any operations' do
            expect(person.reload.username).not_to eq('Emily')
            expect(Post.count).to be(0)
            expect(update_events).to be_empty
          end
        end
      end
    end

    context 'when sessions are supported but transactions are not' do
      min_server_version '3.6'
      # Could also test 4.0 in sharded cluster
      max_server_version '3.6'

      around do |example|
        Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
        Mongoid::Clients.with_name(:other).command(create: :people)

        begin
          subscriber.clear_events!
          person.with(client: :other) do
            example.run
          end
        ensure
          Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
        end
      end

      let!(:error) do
        e = nil
        begin
          person.with_session do |s|
            s.start_transaction
            person.username = 'Emily'
            person.save!
            s.commit_transaction
          end
        rescue => ex
          e = ex
        end
        e
      end

      it 'raises a sessions not supported error' do
        expect(person.reload.username).not_to be('Emily')
        expect(error).to be_a(Mongo::Error::OperationFailure)
      end
    end
  end
end
