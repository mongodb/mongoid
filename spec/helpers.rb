module Helpers

  def expect_query(number)
    events = []

    subscriber = ActiveSupport::Notifications.subscribe('query.moped') do |*args|
      events << ActiveSupport::Notifications::Event.new(*args)
    end
    yield
    expect(events.size).to(eq(number), %[
Expected to receive #{number} queries, it received #{events.size}
#{events.map { |e| e.payload[:ops].map(&:log_inspect) }.join("\n")}
])
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end
