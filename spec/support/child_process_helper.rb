# frozen_string_literal: true
# encoding: utf-8

autoload :ChildProcess, 'childprocess'
autoload :Tempfile, 'tempfile'

module ChildProcessHelper
  module_function def call(cmd, env: nil, cwd: nil)
    process = ChildProcess.new(*cmd)
    process.io.inherit!
    if cwd
      process.cwd = cwd
    end
    if env
      env.each do |k, v|
        process.environment[k.to_s] = v
      end
    end
    process.start
    process.wait
    process
  end

  module_function def check_call(cmd, env: nil, cwd: nil)
    process = call(cmd, env: env, cwd: cwd)
    unless process.exit_code == 0
      raise "Failed to execute: #{cmd}"
    end
  end

  module_function def get_output(cmd, env: nil, cwd: nil)
    process = ChildProcess.new(*cmd)
    process.io.inherit!
    if cwd
      process.cwd = cwd
    end
    if env
      env.each do |k, v|
        process.environment[k.to_s] = v
      end
    end

    output = ''
    r, w = IO.pipe

    begin
      process.io.stdout = w
      process.start
      w.close

      thread = Thread.new do
        begin
          loop do
            output << r.readpartial(16384)
          end
        rescue EOFError
        end
      end

      process.wait
      thread.join
    ensure
      r.close
    end

    [process, output]
  end

  module_function def check_output(*args)
    process, output = get_output(*args)
    unless process.exit_code == 0
      raise "Failed to execute: #{args}"
    end
    output
  end
end
