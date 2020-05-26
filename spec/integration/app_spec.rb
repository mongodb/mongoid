# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

BASE = File.join(File.dirname(__FILE__), '../..')
TMP_BASE = File.join(BASE, 'tmp')

describe 'Mongoid application tests' do
  before(:all) do
    unless %w(1 true yes).include?(ENV['APP_TESTS']&.downcase)
      skip 'Set APP_TESTS=1 in environment to run application tests'
    end

    require 'fileutils'
    require 'support/child_process_helper'
    require 'open-uri'

    FileUtils.mkdir_p(TMP_BASE)
  end

  context 'demo application - sinatra' do
    it 'runs' do
      clone_application(
        'https://github.com/mongoid/mongoid-demo',
        subdir: 'sinatra-minimal',
      ) do

        process = ChildProcess.build(*%w(bundle exec ruby app.rb))
        process.environment.update(clean_env)
        process.io.inherit!
        process.start

        begin
          wait_for_port(4567, 5)
          sleep 1

          uri = URI.parse('http://localhost:4567/posts')
          resp = JSON.parse(uri.open.read)
        ensure
          Process.kill('TERM', process.pid)
          status = process.wait
        end

        resp.should == []

        status.should == 0
      end
    end
  end

  context 'demo application - rails-api' do
    #['~> 5.1.0', '~> 5.2.0', '~> 6.0.0'].each do |rails_version|
    ['~> 6.0.0'].each do |rails_version|
      context "with rails #{rails_version}" do
        it 'runs' do
          clone_application(
            'https://github.com/mongoid/mongoid-demo',
            subdir: 'rails-api',
            rails_version: rails_version,
          ) do

            process = ChildProcess.build(*%w(bundle exec rails s))
            process.environment.update(clean_env)
            process.io.inherit!
            process.start

            begin
              wait_for_port(3000, 5)
              sleep 1

              uri = URI.parse('http://localhost:3000/posts')
              resp = JSON.parse(uri.open.read)
            ensure
              Process.kill('TERM', process.pid)
              status = process.wait
            end

            resp.should == []

            [0, 15].should include(status)
          end
        end
      end
    end
  end

  def clone_application(repo_url, subdir: nil, rails_version: nil)
    Dir.chdir(TMP_BASE) do
      FileUtils.rm_rf(File.basename(repo_url))
      ChildProcessHelper.check_call(%w(git clone) + [repo_url])
      Dir.chdir(File.join(*[File.basename(repo_url), subdir].compact)) do
        gemfile_lines = IO.readlines('Gemfile')
        gemfile_lines.delete_if do |line|
          line =~ /mongoid/
        end
        gemfile_lines << "gem 'mongoid', path: '#{File.expand_path(BASE)}'\n"
        if rails_version
          gemfile_lines.delete_if do |line|
            line =~ /rails/
          end
          gemfile_lines << "gem 'rails', '#{rails_version}'\n"
        end
        File.open('Gemfile', 'w') do |f|
          f << gemfile_lines.join
        end
        ChildProcessHelper.check_call(%w(bundle install), env: clean_env)
        puts `git diff`

        config = {'development' => {'clients' => {'default' => {'uri' => SpecConfig.instance.uri_str}}}}
        File.open('config/mongoid.yml', 'w') do |f|
          f << YAML.dump(config)
        end

        yield
      end
    end
  end

  def clean_env
    @clean_env ||= Hash[ENV.keys.grep(/BUNDLE|RUBYOPT/).map { |k| [k, nil ] }]
  end

  def wait_for_port(port, timeout)
    deadline = Time.now + timeout
    loop do
      begin
        Socket.tcp('localhost', port, nil, nil, connect_timeout: 0.5) do |socket|
          return
        end
      rescue IOError, SystemCallError
        if Time.now > deadline
          raise
        end
      end
    end
  end
end
