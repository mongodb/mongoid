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
    Mongoid::Clients.with_name(:other).instance_variable_get(:@monitoring).subscribers['Command'].find do |s|
      s.is_a?(EventSubscriber)
    end
  end

  let(:insert_events) do
    subscriber.started_events.select { |event| event.command_name == :insert }
  end

  let(:update_events) do
    subscriber.started_events.select { |event| event.command_name == :update }
  end

  context 'when a session is used on a model class' do

    context 'when sessions are supported', if: sessions_supported? do

      around do |example|
        Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
        subscriber.clear_events!
        Person.with(client: :other) do
          example.run
        end
        Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
      end

      context 'when the operations in the session block are all on the class' do

        before do
          Person.with_session do
            Person.create
            Person.create
          end
        end

        let(:insert_events) do
          subscriber.started_events.select { |event| event.command['insert'] }
        end

        it 'uses a single session id for all operations on the class' do
          expect(Person.count).to be(2)
          expect(insert_events).not_to be_empty
          expect(insert_events.collect { |event| event.command['lsid'] }.uniq.size).to eq(1)
        end
      end

      context 'when the operations in the session block are also on another class' do

        context 'when the other class uses the same client' do

          before do
            Post.with(client: :other) do
              Person.with_session do
                Person.create
                Person.create
                Post.create
              end
            end
          end

          it 'uses a single session id for all operations on the class' do
            expect(insert_events).not_to be_empty
            expect(Post.with(client: :other) { |klass| klass.count }).to be(1)
            expect(insert_events.collect { |event| event.command['lsid'] }.uniq.size).to eq(1)
          end
        end

        context 'when the other class uses a different client' do

          let!(:error) do
            e = nil
            begin
              Person.with_session do
                Person.create
                Person.create
                Post.create
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
            expect(insert_events).not_to be_empty
            expect(insert_events.collect { |event| event.command['lsid'] }.uniq.size).to eq(1)
          end
        end

        context 'when sessions are nested' do

          let!(:error) do
            e = nil
            begin
              Person.with_session do
                Person.with_session do
                  Person.create
                  Post.create
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

    context 'when sessions are not supported', unless: sessions_supported? do

      let!(:error) do
        e = nil
        begin
          Person.with_session {}
        rescue => ex
          e = ex
        end
        e
      end

      it 'raises a sessions not supported error' do
        expect(error).to be_a(Mongoid::Errors::InvalidSessionUse)
        expect(error.message).to include('not supported')
      end
    end
  end

  context 'when a session is used on a model instance' do

    let(:person) do
      Person.with(client: :other) do |klass|
        klass.create
      end
    end

    context 'when sessions are supported', if: sessions_supported? do

      around do |example|
        Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
        subscriber.clear_events!
        person.with(client: :other) do
          example.run
        end
        Mongoid::Clients.with_name(:other).database.collections.each(&:drop)
      end

      context 'when the operations in the session block are all on the class' do

        before do
          person.with_session do
            person.username = 'Emily'
            person.save
            person.age = 80
            person.save
          end
        end

        it 'uses a single session id for all operations on the class' do
          expect(person.reload.username).to eq('Emily')
          expect(person.reload.age).to eq(80)
          expect(update_events).not_to be_empty
          expect(update_events.collect { |event| event.command['lsid'] }.uniq.size).to eq(1)
        end
      end

      context 'when the operations in the session block are also on another class' do

        context 'when the other class uses the same client' do

          before do
            Post.with(client: :other) do
              person.with_session do
                person.username = 'Emily'
                person.save
                person.posts << Post.create
              end
            end
          end

          it 'uses a single session id for all operations on the class' do
            expect(person.reload.username).to eq('Emily')
            expect(Post.with(client: :other) { Post.count }).to be(1)
            expect(update_events).not_to be_empty
            expect(update_events.collect { |event| event.command['lsid'] }.uniq.size).to eq(1)
          end
        end

        context 'when the other class uses a different client' do

          let!(:error) do
            e = nil
            begin
              person.with_session do
                person.username = 'Emily'
                person.save
                person.posts << Post.create
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
            expect(update_events.collect { |event| event.command['lsid'] }.uniq.size).to eq(1)
          end
        end

        context 'when sessions are nested' do

          let!(:error) do
            e = nil
            begin
              person.with_session do
                person.with_session do
                  person.username = 'Emily'
                  person.save
                  person.posts << Post.create
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

    context 'when sessions are not supported', unless: sessions_supported? do

      let!(:error) do
        e = nil
        begin
          person.with_session {}
        rescue => ex
          e = ex
        end
        e
      end

      it 'raises a sessions not supported error' do
        expect(error).to be_a(Mongoid::Errors::InvalidSessionUse)
        expect(error.message).to include('not supported')
      end
    end
  end
end
