require 'spec_helper'

describe Mongoid::Sessions::SessionPool do

  let!(:session_pool) do
    Mongoid::Sessions.session_pool(:default)
  end

  let!(:before_run_available_sessions) do
    session_pool.available
  end

  describe '.checkout' do

    it 'Checks out session from the available pool and put in reserved_sessions' do
      expect(session_pool.checkout).to be_a(Moped::Session)
      expect(session_pool.session_for(Thread.current)).
        to be_a(Moped::Session)

      unless before_run_available_sessions.count == 0
        expect(session_pool.available.count).
          to eq (before_run_available_sessions.count - 1)
      else
        expect(session_pool.available.count).to eq(0)
      end
    end

    context 'When all sessions are checked out' do
      let(:session_pool) do
        Mongoid::Sessions::SessionPool.new(
          size: 0,
          name: :default,
          checkout_timeout: 0.001)
      end

      it 'Waits the checkout_timeout period and returns an error' do
        expect { session_pool.checkout }.
          to raise_error(Mongoid::Sessions::SessionPool::Queue::ConnectionTimeoutError)
      end
    end

  end

  describe '.checkin' do
    before do
      session_pool.clear
    end

    let(:session) do
      session_pool.checkout
    end

    it 'Checks a session back into the available pool' do
      expect(session_pool.checkin(session)).to be true

      expect(session_pool.available.count).to eq 1

      expect(session_pool.session_for(Thread.current)).
        to be nil

      expect(session_pool.sessions.count).to eq 1
    end
  end

  describe '.checkin_from_thread' do
    let(:session) do
      session_pool.checkout
    end

    it 'Checks in the session for the given thread' do
      expect(session_pool.checkin_from_thread(Thread.current)).
        to be true
    end
  end

  describe '.clear' do
    before do
      # Make sure there is something in session.sessions first
      session_pool.checkout
    end

    before do
      session_pool.clear
    end

    it 'Clears the sessions for the given thread' do
      expect(session_pool.sessions.count).to be 0
    end

  end

  describe '.reap' do

    let(:thread) do
      Thread.new { session_pool.checkout }
    end

    it 'Reaps sessions from dead/sleeping threads' do
      thread.join

      expect(session_pool.reap).to be_true

      session_pool.session_for(thread).should be_nil
    end

  end

  describe '.session_for' do

    before do
      session_pool.clear
      session_pool.checkout
    end

    it 'Gets the session for the given thread' do
      expect(session_pool.session_for(Thread.current)).
        to be_a Moped::Session
    end
  end

end
