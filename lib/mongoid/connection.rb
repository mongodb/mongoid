require "mongo"

module Mongo
  # patch Mongo::Connection to include custom instrument method
  class Connection
    def instrumenter
      @instrumenter ||= ActiveSupport::Notifications.instrumenter
    end
    
    def instrument(name, payload = {}, &blk)
      instrumenter.instrument(
        "db.mongoid",
        :payload => payload,
        :name    => name) { yield }
    rescue Exception => e
      message = "#{e.class.name}: #{e.message}: #{payload}"
      @logger.debug message if @logger
      raise e
    end
  end
end
