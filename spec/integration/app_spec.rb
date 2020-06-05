# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

BASE = File.join(File.dirname(__FILE__), '../..')
TMP_BASE = File.join(BASE, 'tmp')

describe 'Mongoid application tests' do
  before(:all) do
    unless SpecConfig.instance.app_tests?
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
          # JRuby needs a long timeout
          wait_for_port(4567, 20)
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
              # JRuby needs a long timeout
              wait_for_port(3000, 30)
              sleep 1

              uri = URI.parse('http://localhost:3000/posts')
              resp = JSON.parse(uri.open.read)
            ensure
              Process.kill('TERM', process.pid)
              status = process.wait
            end

            resp.should == []

            # 143 = 128 + 15
            [0, 15, 143].should include(status)
          end
        end
      end
    end
  end

  context 'new application - rails' do
    ['~> 5.1.0', '~> 5.2.0', '~> 6.0.0'].each do |rails_version|
      context "with rails #{rails_version}" do
        it 'creates' do
          ChildProcessHelper.check_call(%w(gem uni rails -a))
          ChildProcessHelper.check_call(%w(gem install rails --no-document -v) + [rails_version])

          Dir.chdir(TMP_BASE) do
            FileUtils.rm_rf('mongoid-test')
            ChildProcessHelper.check_call(%w(rails new mongoid-test --skip-spring --skip-active-record), env: clean_env)

            Dir.chdir('mongoid-test') do
              adjust_app_gemfile
              ChildProcessHelper.check_call(%w(bundle install), env: clean_env)

              ChildProcessHelper.check_call(%w(rails g model post), env: clean_env)
              ChildProcessHelper.check_call(%w(rails g model comment post:belongs_to), env: clean_env)

              # https://jira.mongodb.org/browse/MONGOID-4885
              comment_text = File.read('app/models/comment.rb')
              comment_text.should =~ /belongs_to :post/
              comment_text.should_not =~ /embedded_in :post/
            end
          end
        end
      end
    end
  end

  context 'local test applications' do
    let(:client) { Mongoid.default_client }

    describe 'create_indexes rake task' do

      APP_PATH = File.join(File.dirname(__FILE__), '../../test-apps/rails-api')

      %w(development production).each do |rails_env|
        context "in #{rails_env}" do

          %w(classic zeitwerk).each do |autoloader|
            context "with #{autoloader} autoloader" do

              let(:env) do
                clean_env.merge(RAILS_ENV: rails_env, AUTOLOADER: autoloader)
              end

              before do
                Dir.chdir(APP_PATH) do
                  remove_bundler_req
                  ChildProcessHelper.check_call(%w(bundle install), env: env)
                  write_mongoid_yml
                end

                client['posts'].drop
                client['posts'].create
              end

              it 'creates an index' do
                index = client['posts'].indexes.detect do |index|
                  index['key'] == {'subject' => 1}
                end
                index.should be nil

                ChildProcessHelper.check_call(%w(rake db:mongoid:create_indexes),
                  cwd: APP_PATH, env: env)

                index = client['posts'].indexes.detect do |index|
                  index['key'] == {'subject' => 1}
                end
                index.should be_a(Hash)
              end
            end
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
        adjust_app_gemfile(rails_version: rails_version)
        ChildProcessHelper.check_call(%w(bundle install), env: clean_env)
        puts `git diff`

        write_mongoid_yml

        yield
      end
    end
  end

  def write_mongoid_yml
    env_config = {'clients' => {'default' => {
      # TODO massive hack, will fail if uri specifies a database name or
      # any uri options
      'uri' => "#{SpecConfig.instance.uri_str}/mongoid_test",
    }}}
    config = {'development' => env_config, 'production' => env_config}
    File.open('config/mongoid.yml', 'w') do |f|
      f << YAML.dump(config)
    end
  end

  def adjust_app_gemfile(rails_version: nil)
    remove_bundler_req

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
  end

  def remove_bundler_req
    lock_lines = IO.readlines('Gemfile.lock')
    # Get rid of the bundled with line so that whatever bundler is installed
    # on the system is usable with the application.
    if i = lock_lines.index("BUNDLED WITH\n")
      lock_lines.slice!(i, 2)
      File.open('Gemfile.lock', 'w') do |f|
        f << lock_lines.join
      end
    end
  end

  def remove_spring
    # Spring produces this error in Evergreen:
    # /data/mci/280eb2ecf4fd69208e2106cd3af526f1/src/rubies/ruby-2.7.0/lib/ruby/gems/2.7.0/gems/spring-2.1.0/lib/spring/client/run.rb:26:
    # in `initialize': too long unix socket path (126bytes given but 108bytes max) (ArgumentError)
    # Is it trying to create unix sockets in current directory?
    # https://stackoverflow.com/questions/30302021/rails-runner-without-spring
    ChildProcessHelper.check_call(%w(bin/spring binstub --remove --all), env: clean_env)
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
