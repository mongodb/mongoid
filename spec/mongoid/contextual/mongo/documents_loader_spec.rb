# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Contextual::Mongo::DocumentsLoader do
  # https://jira.mongodb.org/browse/MONGOID-5505
  require_mri

  let(:view) do
    double('view').tap do |view|
      allow(view).to receive(:map)
    end
  end

  let(:klass) do
    double
  end

  let(:criteria) do
    double('criteria').tap do |criteria|
      allow(criteria).to receive(:inclusions).and_return([])
    end
  end

  let(:executor) do
    described_class.executor
  end

  let(:subject) do
    described_class.new(view, klass, criteria, executor: executor)
  end

  context 'state management' do
    let(:executor) do
      # Such executor will never execute a task, so it guarantees that
      # our task will stay in its initial state.
      Concurrent::ThreadPoolExecutor.new(
        min_threads: 0,
        max_threads: 0,
      )
    end

    describe '#initialize' do
      it 'initializes in pending state' do
        expect(subject.pending?).to be_truthy
        expect(subject.started?).to be_falsey
      end
    end

    describe '#unschedule' do
      it 'changes state' do
        subject.unschedule
        expect(subject.pending?).to be_falsey
        expect(subject.started?).to be_falsey
      end
    end

    describe '#execute' do
      it 'does not change state' do
        prev_started = subject.started?
        prev_pending = subject.pending?
        subject.execute
        expect(subject.started?).to eq(prev_started)
        expect(subject.pending?).to eq(prev_pending)
      end
    end

    context 'when the task is completed' do
      let(:executor) do
        Concurrent::ImmediateExecutor.new
      end

      it 'changes the state to started' do
        subject.wait!
        expect(subject.started?).to be_truthy
        expect(subject.pending?).to be_falsey
      end
    end
  end

  context 'loading documents' do
    let(:view) do
      klass.collection.find(criteria.selector, session: criteria.send(:_session))
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    let(:klass) do
      Band
    end

    let!(:band) do
      Band.create!(name: 'Depeche Mode')
    end

    context 'asynchronously' do
      it 'loads documents' do
        subject.wait!
        expect(subject.value).to eq([band])
      end
    end

    context 'synchronously' do
      let(:executor) do
        # Such executor will never execute a task, so it guarantees that
        # our task will stay in its initial state.
        Concurrent::ThreadPoolExecutor.new(
          min_threads: 0,
          max_threads: 0,
        )
      end

      it 'loads documents' do
        expect(subject.execute).to eq([band])
      end
    end
  end

  describe '.executor' do
    context 'when immediate executor requested' do
      it 'returns immediate executor' do
        expect(
          described_class.executor(:immediate)
        ).to eq(described_class.immediate_executor)
      end
    end

    context 'when global thread pool executor requested' do
      it 'returns global thread pool executor' do
        expect(
          described_class.executor(:global_thread_pool)
        ).to eq(described_class.global_thread_pool_async_query_executor)
      end
    end

    context 'when an unknown executor requested' do
      it 'raises an error' do
        expect do
          described_class.executor(:i_am_an_invalid_option)
        end.to raise_error(Mongoid::Errors::InvalidQueryExecutor)
      end
    end
  end

  describe ".global_thread_pool_async_query_executor" do
    before(:each) do
      described_class.class_variable_set(:@@global_thread_pool_async_query_executor, nil)
    end

    after(:each) do
      described_class.class_variable_set(:@@global_thread_pool_async_query_executor, nil)
    end

    context 'when global_executor_concurrency option is set' do
      config_override :global_executor_concurrency, 50

      it 'returns an executor' do
        executor = described_class.global_thread_pool_async_query_executor
        expect(executor).not_to be_nil
        expect(executor.max_length).to eq( 50 )
      end
    end

    context 'when global_executor_concurrency option is not set' do
      it 'returns an executor' do
        executor = described_class.global_thread_pool_async_query_executor
        expect(executor).not_to be_nil
        expect(executor.max_length).to eq( 4 )
      end
    end

    context 'when global_executor_concurrency option changes' do
      config_override :global_executor_concurrency, 50

      it 'creates new executor' do
        first_executor = described_class.global_thread_pool_async_query_executor
        Mongoid.global_executor_concurrency = 100
        second_executor = described_class.global_thread_pool_async_query_executor

        expect(first_executor).not_to eq(second_executor)
        expect(second_executor.max_length).to eq( 100 )
      end
    end
  end
end
