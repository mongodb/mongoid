class CallbackRecorder < Mongoid::Observer
  observe :actor

  attr_reader :last_callback, :call_count, :last_record

  def initialize
    reset
    super
  end

  def reset
    @last_callback = nil
    @call_count = Hash.new(0)
    @last_record = {}
  end

  Mongoid::Callbacks.observables.each do |callback|
    define_method(callback) do |record, &block|
      @last_callback = callback
      @call_count[callback] += 1
      @last_record[callback] = record
      block ? block.call : true
    end
  end
end
