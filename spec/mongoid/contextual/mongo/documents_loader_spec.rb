# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Contextual::Mongo::DocumentsLoader do
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
    context 'when immediate executor configured' do
      config_override :async_query_executor, :immediate

      it 'returns immediate executor' do
        expect(described_class.executor).to eq(described_class::IMMEDIATE_EXECUTOR)
      end
    end

    context 'when global thread pool executor configured' do
      config_override :async_query_executor, :global_thread_pool

      it 'returns global thread pool executor' do
        expect(described_class.executor).to eq(Mongoid.global_thread_pool_async_query_executor)
      end
    end
  end
end
