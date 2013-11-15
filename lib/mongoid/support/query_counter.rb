module Mongoid

  class QueryCounter
    attr_reader :events

    def initialize
      @events = []
    end

    def instrument
      subscriber = ActiveSupport::Notifications.subscribe('query.moped') do |*args|
        @events << ActiveSupport::Notifications::Event.new(*args)
      end
      yield
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    def inspect
      @events.map { |e| e.payload[:ops].map(&:log_inspect) }.join("\n")
    end
  end
end
