# frozen_string_literal: true

require "spec_helper"
require "mongoid/railties/controller_runtime"

describe "Mongoid::Railties::ControllerRuntime" do
  controller_runtime = Mongoid::Railties::ControllerRuntime
  collector = controller_runtime::Collector

  def set_metric value
    Thread.current["Mongoid.controller_runtime"] = value
  end

  def clear_metric!
    set_metric 0
  end

  describe "Collector" do

    it "stores the metric in thread-safe manner" do
      clear_metric!
      expect(collector.runtime).to eq(0)
      set_metric 42
      expect(collector.runtime).to eq(42)
    end

    it "sets metric on both succeeded and failed" do
      instance = collector.new
      event_payload = OpenStruct.new duration: 42

      clear_metric!
      instance.succeeded event_payload
      expect(collector.runtime).to eq(42000)

      clear_metric!
      instance.failed event_payload
      expect(collector.runtime).to eq(42000)
    end

    it "resets the metric and returns the value" do
      clear_metric!
      expect(collector.reset_runtime).to eq(0)
      set_metric 42
      expect(collector.reset_runtime).to eq(42)
      expect(collector.runtime).to eq(0)
    end

  end

  reference_controller_class = Class.new do
    def process_action *_
      @process_action = true
    end

    def cleanup_view_runtime *_
      @cleanup_view_runtime.call
    end

    def append_info_to_payload *_
      @append_info_to_payload = true
    end

    def self.log_process_action *_
      @log_process_action.call
    end
  end

  controller_class = Class.new reference_controller_class do
    include controller_runtime::ControllerExtension
  end

  let(:controller){ controller_class.new }

  it "resets the metric before each action" do
    set_metric 42
    controller.send(:process_action, 'foo')
    expect(collector.runtime).to be(0)
    expect(controller.instance_variable_get "@process_action").to be(true)
  end

  it "strips the metric of other sources of the runtime" do
    set_metric 1
    controller.instance_variable_set "@cleanup_view_runtime", ->{
      controller.instance_variable_set "@cleanup_view_runtime", true
      set_metric 13
      42
    }
    returned = controller.send :cleanup_view_runtime
    expect(controller.instance_variable_get "@cleanup_view_runtime").to be(true)
    expect(controller.mongoid_runtime).to eq(14)
    expect(returned).to be(29)
  end

  it "appends the metric to payload" do
    payload = {}
    set_metric 42
    controller.send :append_info_to_payload, payload
    expect(controller.instance_variable_get "@append_info_to_payload").to be(true)
    expect(payload[:mongoid_runtime]).to eq(42)
  end

  it "adds metric to log message" do
    controller_class.instance_variable_set "@log_process_action", ->{
      controller_class.instance_variable_set "@log_process_action", true
      []
    }
    messages = controller_class.log_process_action mongoid_runtime: 42.101
    expect(controller_class.instance_variable_get "@log_process_action").to be(true)
    expect(messages).to eq(["MongoDB: 42.1ms"])
  end

end
