# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"
require_relative './transactions_spec_models'

def capture_exception
  e = nil
  begin
    yield
  rescue => ex
    e = ex
  end
  e
end

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
        shared_examples 'it does not use the transaction for that thread' do
          it do
            expect(Person.count).to be(2)
            expect(Person.with(client: :default) { Person.count }).to be(1)
            expect(insert_events.count { |e| e.command['startTransaction'] }).to be(1)
            expect(other_events.count { |e| e.command_name == 'commitTransaction' }).to be(1)
          end
        end

        context 'using #with_session' do
          let!(:last_use_diff) do
            Person.with_session do |s|
              s.start_transaction
              Person.create!
              Person.create!
              Thread.new { Person.create! }.value
              s.commit_transaction
            end
          end

          include_examples 'it does not use the transaction for that thread'
        end

        context 'using #transaction' do
          let!(:last_use_diff) do
            Person.transaction do
              Person.create!
              Person.create!
              Thread.new { Person.create! }.value
            end
          end

          include_examples 'it does not use the transaction for that thread'
        end
      end

      context 'when the operations in the transactions block are all on the class' do
        shared_examples 'it uses a single transaction number for all operations on the class' do
          it do
            expect(Person.count).to be(2)
            expect(insert_events_txn_numbers.size).to eq(2)
            expect(insert_events_txn_numbers.uniq.size).to eq(1)
          end
        end

        context 'using #with_session' do
          before do
            Person.with_session do |s|
              s.start_transaction
              Person.create!
              Person.create!
              s.commit_transaction
            end
          end

          include_examples 'it uses a single transaction number for all operations on the class'
        end

        context 'using #transaction' do
          before do
            Person.transaction do
              Person.create!
              Person.create!
            end
          end

          include_examples 'it uses a single transaction number for all operations on the class'
        end
      end

      context 'when the operations in the transactions block are also on another class' do
        context 'when the other class uses the same client' do
          shared_examples 'it uses a single transaction number for all operations on the class' do
            it do
              expect(Post.with(client: :other) { |klass| klass.count }).to be(1)
              expect(insert_events_txn_numbers.size).to eq(3)
              expect(insert_events_txn_numbers.uniq.size).to eq(1)
            end
          end

          context 'using #with_session' do
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

            include_examples 'it uses a single transaction number for all operations on the class'
          end

          context 'using #transaction' do
            before do
              Post.with(client: :other) do
                Person.transaction do
                  Person.create!
                  Person.create!
                  Post.create!
                end
              end
            end

            include_examples 'it uses a single transaction number for all operations on the class'
          end
        end

        context 'when the other class uses a different client' do
          shared_examples 'it does not abort the transaction' do
            it 'does not raise an error' do
              expect(error).to be_nil
            end

            it 'committed the transaction' do
              expect(Person.count).to be(2)
              expect(Post.count).to be(1)
              expect(insert_events_txn_numbers.size).to eq(2)
              expect(other_events.count { |e| e.command_name == 'abortTransaction'}).to be(0)
              expect(other_events.count { |e| e.command_name == 'commitTransaction'}).to be(1)
            end
          end

          context 'using #with_session' do
            let!(:error) do
              capture_exception do
                Person.with_session do |s|
                  s.start_transaction
                  Person.create!
                  Person.create!
                  Post.create!
                  s.commit_transaction
                end
              end
            end

            include_examples 'it does not abort the transaction'
          end

          context 'using #transaction' do
            let!(:error) do
              capture_exception do
                Person.transaction do
                  Person.create!
                  Person.create!
                  Post.create!
                end
              end
            end

            include_examples 'it does not abort the transaction'
          end
        end

        context 'when transactions are nested' do
          shared_examples 'it aborts the transaction' do |error_class|
            it 'raises an error' do
              expect(error).to be_a(error_class)
            end

            it 'does not execute any operations' do
              expect(Person.count).to be(0)
              expect(Post.count).to be(0)
              expect(insert_events).to be_empty
            end
          end

          context 'using #with_session' do
            let!(:error) do
              capture_exception do
                Person.with_session do |s|
                  s.start_transaction
                  s.start_transaction
                  Person.create!
                  Post.create!
                  s.commit_transaction
                end
              end
            end

            include_examples 'it aborts the transaction', Mongo::Error::InvalidTransactionOperation
          end

          context 'using #transaction' do
            let!(:error) do
              capture_exception do
                Person.transaction do
                  Person.transaction do
                    Person.create!
                    Post.create!
                  end
                end
              end
            end

            include_examples 'it aborts the transaction', Mongoid::Errors::InvalidTransactionNesting
          end
        end
      end

      context 'when reloading an embedded document created inside a transaction' do
        context 'using #with_session' do
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

        context 'using #transaction' do
          it 'does not raise an error and has the correct document' do
            Canvas.transaction do

              p = Palette.new
              c = Canvas.new(palette: p)
              c.save!

              expect do
                p.reload
              end.to_not raise_error

              expect(c.palette).to eq(p)
            end
          end
        end
      end

      context 'when Mongoid::Errors:Rollback raised' do
        let!(:error) do
          capture_exception do
            Person.transaction do
              Person.create!
              raise Mongoid::Errors::Rollback
            end
          end
        end

        it 'does not bass on the exception' do
          expect(error).to be_nil
        end

        it 'aborts the transaction' do
          expect(other_events.count { |e| e.command_name == 'abortTransaction'}).to be(1)
          expect(other_events.count { |e| e.command_name == 'commitTransaction'}).to be(0)
        end
      end
    end

    context 'when sessions are supported but transactions are not' do
      min_server_version '3.6'
      # Could also test 4.0 in sharded cluster
      max_server_version '3.6.99'

      shared_examples 'it raises a transactions not supported error' do
        it do
          expect(Person.count).to eq(0)
          expect(error).to be_a(Mongoid::Errors::TransactionsNotSupported)
        end
      end

      context 'using #with_session' do
        let!(:error) do
          capture_exception do
            Person.with_session do |s|
              s.start_transaction
              Person.create!
              s.commit_transaction
            end
          end
        end

        include_examples 'it raises a transactions not supported error'
      end

      context 'using #transaction' do
        let!(:error) do
          capture_exception do
            Person.transaction do
              Person.create!
            end
          end
        end

        include_examples 'it raises a transactions not supported error'
      end
    end

    context 'when transactions are not supported' do
      require_topology :single

      it 'it raises a transactions not supported error' do
        expect do
          Person.transaction do
            Person.create!
          end
        end.to raise_error(Mongoid::Errors::TransactionsNotSupported)
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
        shared_examples 'it uses a single transaction number for all operations on the class' do
          it do
            expect(person.reload.username).to eq('Emily')
            expect(person.reload.age).to eq(80)
            expect(update_events_txn_numbers.size).to eq(2)
            expect(update_events_txn_numbers.uniq.size).to eq(1)
          end
        end

        context 'using #with_session' do
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

          include_examples 'it uses a single transaction number for all operations on the class'
        end

        context 'using #transaction' do
          before do
            person.transaction do
              person.username = 'Emily'
              person.save!
              person.age = 80
              person.save!
            end
          end

          include_examples 'it uses a single transaction number for all operations on the class'
        end
      end

      context 'when the operations in the transaction block are also on another class' do

        context 'when the other class uses the same client' do
          shared_examples 'it uses a single transaction number for all operations on the class' do
            it do
              expect(person.reload.username).to eq('Emily')
              expect(Post.with(client: :other) { Post.count }).to be(1)
              expect(update_events_txn_numbers.size).to eq(3) # person update, counter cache, post assignment
              expect(update_events_txn_numbers.uniq.size).to eq(1) # person update, counter cache, post assignment
              expect(insert_events_txn_numbers.size).to eq(2)
              expect(insert_events_txn_numbers.uniq.size).to eq(1)
              expect(update_events_txn_numbers.uniq).to eq(insert_events_txn_numbers.uniq)
            end
          end

          context 'using #with_session' do
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

            include_examples 'it uses a single transaction number for all operations on the class'
          end

          context 'using #transaction' do
            before do
              Post.with(client: :other) do
                person.transaction do
                  person.username = 'Emily'
                  person.save!
                  person.posts << Post.create!
                end
              end
            end

            include_examples 'it uses a single transaction number for all operations on the class'
          end
        end

        context 'when the other class uses a different client' do
          shared_examples 'does not abort the transaction' do
            it 'raises an error' do
              expect(error).to be_nil
            end

            it 'did not abort the transaction' do
              expect(person.reload.username).to eq('Emily')
              expect(Post.count).to be(1)
              expect(update_events_txn_numbers.size).to eq(2)
              expect(insert_events_txn_numbers.size).to eq(1)
            end
          end

          context 'using #with_session' do
            let!(:error) do
              capture_exception do
                person.with_session do |s|
                  s.start_transaction
                  person.username = 'Emily'
                  person.save!
                  person.posts << Post.create!
                  s.commit_transaction
                end
              end
            end

            include_examples 'does not abort the transaction'
          end

          context 'using #transaction' do
            let!(:error) do
              capture_exception do
                person.transaction do
                  person.username = 'Emily'
                  person.save!
                  person.posts << Post.create!
                end
              rescue => ex
              end
            end

            include_examples 'does not abort the transaction'
          end
        end

        context 'when transactions are nested' do
          context 'use #with_session' do
            let!(:error) do
              capture_exception do
                person.with_session do |s|
                  s.start_transaction
                  s.start_transaction
                  person.username = 'Emily'
                  person.save!
                  person.posts << Post.create!
                  s.commit_transaction
                end
              end
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

          context 'use #transaction' do
            let!(:error) do
              capture_exception do
                person.transaction do
                  person.transaction do
                    person.username = 'Emily'
                    person.save!
                    person.posts << Post.create!
                  end
                end
              end
            end

            it 'raises an error' do
              expect(error).to be_a(Mongoid::Errors::InvalidTransactionNesting)
            end

            it 'does not execute any operations' do
              expect(person.reload.username).not_to eq('Emily')
              expect(Post.count).to be(0)
              expect(update_events).to be_empty
            end
          end

        end
      end

      context 'when Mongoid::Errors:Rollback raised' do
        let!(:error) do
          capture_exception do
            person.transaction do
              person.username = 'John'
              person.save!
              raise Mongoid::Errors::Rollback
            end
          end
        end

        it 'does not bass on the exception' do
          expect(error).to be_nil
        end

        it 'aborts the transaction' do
          expect(other_events.count { |e| e.command_name == 'abortTransaction'}).to be(1)
          expect(other_events.count { |e| e.command_name == 'commitTransaction'}).to be(0)
        end
      end
    end

    context 'when sessions are supported but transactions are not' do
      min_server_version '3.6'
      # Could also test 4.0 in sharded cluster
      max_server_version '3.6.99'

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

      context 'using #with_session' do
        let!(:error) do
          capture_exception do
            person.with_session do |s|
              s.start_transaction
              person.username = 'Emily'
              person.save!
              s.commit_transaction
            end
          end
        end

        it 'raises a transactions not supported error' do
          expect(person.reload.username).not_to be('Emily')
          expect(error).to be_a(Mongoid::Errors::TransactionsNotSupported)
        end
      end

      context 'using #transaction' do
        let!(:error) do
          capture_exception do
            person.transaction do
              person.username = 'Emily'
              person.save!
            end
          end
        end

        it 'raises a transactions not supported error' do
          expect(person.reload.username).not_to be('Emily')
          expect(error).to be_a(Mongoid::Errors::TransactionsNotSupported)
        end
      end
    end

    context 'when transactions are not supported' do
      require_topology :single

      it 'it raises a transactions not supported error' do
        expect do
          Person.transaction do
            Person.create!
          end
        end.to raise_error(Mongoid::Errors::TransactionsNotSupported)
      end
    end
  end

  context 'when a transaction is used on Mongoid module' do
    let(:subscriber) do
      Mongoid::Clients.with_name(:default).send(:monitoring).subscribers['Command'].find do |s|
        s.is_a?(EventSubscriber)
      end
    end

    before do
      Mongoid::Clients.with_name(:default).database.collections.each(&:drop)
      Person.collection.create
      Account.collection.create
      Mongoid::Clients.with_name(:default).subscribe(Mongo::Monitoring::COMMAND, EventSubscriber.new)
      subscriber.clear_events!
    end

    after do
      Mongoid::Clients.with_name(:default).database.collections.each(&:drop)
    end

    context 'when transactions are supported' do
      require_transaction_support

      context 'when no error raised' do
        before do
          Mongoid.transaction do
            Person.create!
          end
        end

        it 'commits the transacrion' do
          expect(other_events.count { |e| e.command_name == 'abortTransaction'}).to be(0)
          expect(other_events.count { |e| e.command_name == 'commitTransaction'}).to be(1)
        end

        it 'executes the commands inside the transaction' do
          expect(Person.count).to be(1)
        end
      end

      context 'When an error raised' do
        let!(:error) do
          capture_exception do
            Mongoid.transaction do
              Person.create!
              Account.create!
            end
          end
        end

        it 'aborts the transaction' do
          expect(other_events.count { |e| e.command_name == 'abortTransaction'}).to be(1)
          expect(other_events.count { |e| e.command_name == 'commitTransaction'}).to be(0)
        end

        it 'passes on the error' do
          expect(error).to be_a(Mongoid::Errors::Validations)
        end

        it 'reverts changes' do
          expect(Account.count).to be(0)
          expect(Person.count).to be(0)
        end
      end
    end
  end

  context 'callbacks' do
    shared_examples 'commit callbacks are called' do
      it 'calls after_commit once' do
        expect(subject.after_commit_counter.value).to eq(1)
      end

      it 'does not call after_rollback' do
        expect(subject.after_rollback_counter.value).to eq(0)
      end
    end

    shared_examples 'rollback callbacks are called' do
      it 'does not call after_commit' do
        expect(subject.after_commit_counter.value).to eq(0)
      end

      it 'calls after_rollback once' do
        expect(subject.after_rollback_counter.value).to eq(1)
      end
    end

    context 'with explicit transaction' do
      require_transaction_support

      before do
        Mongoid::Clients.with_name(:default).database.collections.each(&:drop)
        TransactionsSpecPerson.collection.create
        TransactionsSpecPersonWithOnCreate.collection.create
        TransactionsSpecPersonWithOnUpdate.collection.create
        TransactionsSpecPersonWithOnDestroy.collection.create
        TransactionSpecRaisesBeforeSave.collection.create
        TransactionSpecRaisesAfterSave.collection.create
      end

      context 'when commit the transaction' do
        context 'create' do
          context 'without :on option' do
            let!(:subject) do
              person = nil
              TransactionsSpecPerson.transaction do
                person = TransactionsSpecPerson.create!(name: 'James Bond')
              end
              person
            end

            it_behaves_like 'commit callbacks are called'
          end

          context 'when callback has :on option' do
            let!(:subject) do
              person = nil
              TransactionsSpecPersonWithOnCreate.transaction do
                person = TransactionsSpecPersonWithOnCreate.create!(name: 'James Bond')
              end
              person
            end

            it_behaves_like 'commit callbacks are called'
          end
        end

        context 'save' do
          context 'without :on option' do
            let(:subject) do
              TransactionsSpecPerson.create!(name: 'James Bond').tap do |subject|
                subject.after_commit_counter.reset
                subject.after_rollback_counter.reset
              end
            end

            context 'when modified once' do
              before do
                subject.transaction do
                  subject.name = 'Austin Powers'
                  subject.save!
                end
              end

              it_behaves_like 'commit callbacks are called'
            end

            context 'when modified multiple times' do
              before do
                subject.transaction do
                  subject.name = 'Austin Powers'
                  subject.save!
                  subject.name = 'Jason Bourne'
                  subject.save!
                end
              end

              it_behaves_like 'commit callbacks are called'
            end
          end

          context 'with :on option' do
            let(:subject) do
              TransactionsSpecPersonWithOnUpdate.create!(name: 'James Bond').tap do |subject|
                subject.after_commit_counter.reset
                subject.after_rollback_counter.reset
              end
            end

            context 'when modified once' do
              before do
                subject.transaction do
                  subject.name = 'Austin Powers'
                  subject.save!
                end
              end

              it_behaves_like 'commit callbacks are called'
            end

            context 'when modified multiple times' do
              before do
                subject.transaction do
                  subject.name = 'Austin Powers'
                  subject.save!
                  subject.name = 'Jason Bourne'
                  subject.save!
                end
              end

              it_behaves_like 'commit callbacks are called'
            end
          end
        end

        context 'update_attributes' do
          context 'without :on option' do
            let(:subject) do
              TransactionsSpecPerson.create!(name: 'James Bond').tap do |subject|
                subject.after_commit_counter.reset
                subject.after_rollback_counter.reset
              end
            end

            before do
              subject.transaction do
                subject.update_attributes!(name: 'Austin Powers')
              end
            end

            it_behaves_like 'commit callbacks are called'
          end

          context 'when callback has on option' do
            let(:subject) do
              TransactionsSpecPersonWithOnUpdate.create!(name: 'Jason Bourne')
            end

            before do
              TransactionsSpecPersonWithOnUpdate.transaction do
                subject.update_attributes!(name: 'Foma Kiniaev')
              end
            end

            it_behaves_like 'commit callbacks are called'
          end
        end

        context 'destroy' do
          context 'without :on option' do
            let(:after_commit_counter) do
              TransactionsSpecCounter.new
            end

            let(:after_rollback_counter) do
              TransactionsSpecCounter.new
            end

            let(:subject) do
              TransactionsSpecPerson.create!(name: 'James Bond').tap do |p|
                p.after_commit_counter = after_commit_counter
                p.after_rollback_counter = after_rollback_counter
              end
            end

            before do
              subject.transaction do
                subject.destroy
              end
            end

            it_behaves_like 'commit callbacks are called'
          end

          context 'with :on option' do
            let(:after_commit_counter) do
              TransactionsSpecCounter.new
            end

            let(:after_rollback_counter) do
              TransactionsSpecCounter.new
            end

            let(:subject) do
              TransactionsSpecPersonWithOnDestroy.create!(name: 'James Bond').tap do |p|
                p.after_commit_counter = after_commit_counter
                p.after_rollback_counter = after_rollback_counter
              end
            end

            before do
              subject.transaction do
                subject.destroy
              end
            end

            it_behaves_like 'commit callbacks are called'
          end
        end
      end

      context 'when rollback the transaction' do
        context 'create' do
          context 'without :on option' do
            let!(:subject) do
              person = nil
              TransactionsSpecPerson.transaction do
                person = TransactionsSpecPerson.create!(name: 'James Bond')
                raise Mongoid::Errors::Rollback
              end
              person
            end

            it_behaves_like 'rollback callbacks are called'
          end

          context 'with :on option' do
            let!(:subject) do
              person = nil
              TransactionsSpecPersonWithOnCreate.transaction do
                person = TransactionsSpecPersonWithOnCreate.create!(name: 'James Bond')
                raise Mongoid::Errors::Rollback
              end
              person
            end

            it_behaves_like 'rollback callbacks are called'
          end
        end

        context 'save' do
          let(:subject) do
            TransactionsSpecPerson.create!(name: 'James Bond').tap do |subject|
              subject.after_commit_counter.reset
              subject.after_rollback_counter.reset
            end
          end

          context 'when modified once' do
            before do
              begin
                subject.transaction do
                  subject.name = 'Austin Powers'
                  subject.save!
                  raise 'Something went wrong'
                end
              rescue RuntimeError
              end
            end

            it_behaves_like 'rollback callbacks are called'
          end

          context 'when modified multiple times' do
            before do
              subject.transaction do
                subject.name = 'Austin Powers'
                subject.save!
                subject.name = 'Jason Bourne'
                subject.save!
                raise Mongoid::Errors::Rollback
              end
            end

            it_behaves_like 'rollback callbacks are called'
          end

          context 'when exception is raised in a callback' do
            context 'in before_save' do
              let(:subject) do
                TransactionSpecRaisesBeforeSave.new
              end

              before do
                begin
                  subject.transaction do
                    subject.save!
                  end
                rescue RuntimeError
                end
              end

              it 'does not call any transaction callbacks' do
                # This is according to Rails behavior
                expect(subject.after_commit_counter.value).to eq(0)
                expect(subject.after_rollback_counter.value).to eq(0)
              end
            end

            context 'in after_save' do
              let(:subject) do
                TransactionSpecRaisesAfterSave.new
              end

              before do
                begin
                  subject.transaction do
                    subject.save!
                  end
                rescue RuntimeError
                end
              end

              it_behaves_like 'rollback callbacks are called'
            end
          end
        end

        context 'update_attributes' do
          let(:subject) do
            TransactionsSpecPerson.create!(name: 'James Bond').tap do |p|
              p.after_commit_counter.reset
              p.after_rollback_counter.reset
            end
          end

          before do
            subject.transaction do
              subject.update_attributes!(name: 'Austin Powers')
              raise Mongoid::Errors::Rollback
            end
          end

          it_behaves_like 'rollback callbacks are called'
        end

        context 'destroy' do
          let(:after_commit_counter) do
            TransactionsSpecCounter.new
          end

          let(:after_rollback_counter) do
            TransactionsSpecCounter.new
          end

          let(:subject) do
            TransactionsSpecPerson.create!(name: 'James Bond').tap do |p|
              p.after_commit_counter = after_commit_counter
              p.after_rollback_counter = after_rollback_counter
            end
          end

          before do
            subject.transaction do
              subject.destroy
              raise Mongoid::Errors::Rollback
            end
          end

          it_behaves_like 'rollback callbacks are called'
        end
      end
    end

    context 'without explicit transaction' do
      context 'when operation is successful' do
        context 'create' do
          let!(:subject) do
            TransactionsSpecPerson.create!(name: 'James Bond')
          end

          it_behaves_like 'commit callbacks are called'
        end

        context 'save' do
          let(:subject) do
            TransactionsSpecPerson.create!(name: 'James Bond').tap do |person|
              person.after_commit_counter.reset
              person.after_rollback_counter.reset
            end
          end

          before do
            subject.name = 'Jason Bourne'
            subject.save!
          end

          it_behaves_like 'commit callbacks are called'
        end

        context 'save' do
          let(:subject) do
            TransactionsSpecPerson.create!(name: 'James Bond').tap do |person|
              person.after_commit_counter.reset
              person.after_rollback_counter.reset
            end
          end

          before do
            subject.update_attributes!(name: 'Jason Bourne')
          end

          it_behaves_like 'commit callbacks are called'
        end

        context 'destroy' do
          let(:subject) do
            TransactionsSpecPerson.create!(name: 'James Bond').tap do |person|
              person.after_commit_counter.reset
              person.after_rollback_counter.reset
            end
          end

          before do
            subject.destroy
          end

          it_behaves_like 'commit callbacks are called'
        end
      end
    end
  end
end
