# frozen_string_literal: true
# rubocop:todo all

require 'spec_helper'

BASE = File.join(File.dirname(__FILE__), '../..')
TMP_BASE = File.join(BASE, 'tmp')

def check_call(cmd, **opts)
  puts "Executing #{cmd.join(' ')}"
  Mrss::ChildProcessHelper.check_call(cmd, **opts)
end

def gem_version_argument(version)
  "_#{version}_" if version
end

def insert_rails_gem_version(cmd)
  gem_version = gem_version_argument(SpecConfig.instance.installed_rails_version)
  cmd.tap { cmd[1,0] = gem_version if gem_version }
end

describe 'Mongoid application tests' do
  before(:all) do
    unless SpecConfig.instance.app_tests?
      skip 'Set APP_TESTS=1 in environment to run application tests'
    end

    require 'fileutils'
    require 'mrss/child_process_helper'
    require 'open-uri'

    FileUtils.mkdir_p(TMP_BASE)
  end

  context 'demo application' do
    context 'sinatra' do
      it 'runs' do
        clone_application(
          'https://github.com/mongoid/mongoid-demo',
          subdir: 'sinatra-minimal',
        ) do

          # JRuby needs a long timeout
          start_app(%w(bundle exec ruby app.rb), 4567, 40) do |port|
            uri = URI.parse('http://localhost:4567/posts')
            resp = JSON.parse(uri.open.read)

            resp.should == []

          end
        end
      end
    end

    context 'rails-api' do
      it 'runs' do
        clone_application(
          'https://github.com/mongoid/mongoid-demo',
          subdir: 'rails-api',
        ) do

          # JRuby needs a long timeout
          start_app(%w(bundle exec rails s), 3000, 50) do |port|
            uri = URI.parse('http://localhost:3000/posts')
            resp = JSON.parse(uri.open.read)

            resp.should == []
          end
        end
      end
    end
  end

  def start_app(cmd, port, timeout)
    process = ChildProcess.build(*cmd)
    process.environment.update(clean_env)
    process.io.inherit!
    process.start

    begin
      wait_for_port(port, timeout, process)
      sleep 1

      rv = yield port
    ensure
      # The process may have already died (due to an error exit) -
      # in this case killing it will raise an exception.
      Process.kill('TERM', process.pid) rescue nil
      status = process.wait
    end

    # Exit should be either success or SIGTERM
    allowed_statuses = [0, 15, 128 + 15]
    if RUBY_PLATFORM == 'java'
      # Puma on JRuby exits with status 1 when it receives a TERM signal.
      allowed_statuses << 1
    end
    allowed_statuses.should include(status)

    rv
  end

  def prepare_new_rails_app(name)
    install_rails

    Dir.chdir(TMP_BASE) do
      FileUtils.rm_rf(name)
      check_call(insert_rails_gem_version(%W(rails new #{name} --skip-spring --skip-active-record)), env: clean_env)

      Dir.chdir(name) do
        adjust_rails_defaults
        adjust_app_gemfile
        check_call(%w(bundle install), env: clean_env)

        yield
      end
    end
  end

  context 'new application - rails' do
    it 'creates' do
      prepare_new_rails_app 'mongoid-test' do
        check_call(%w(rails g model post), env: clean_env)
        check_call(%w(rails g model comment post:belongs_to), env: clean_env)

        # https://jira.mongodb.org/browse/MONGOID-4885
        comment_text = File.read('app/models/comment.rb')
        comment_text.should =~ /belongs_to :post/
        comment_text.should_not =~ /embedded_in :post/
      end
    end

    it 'generates Mongoid config' do
      prepare_new_rails_app 'mongoid-test-config' do
        mongoid_config_file = File.join(TMP_BASE, 'mongoid-test-config/config/mongoid.yml')

        File.exist?(mongoid_config_file).should be false
        check_call(%w(rails g mongoid:config), env: clean_env)
        File.exist?(mongoid_config_file).should be true

        config_text = File.read(mongoid_config_file)
        expect(config_text).to match /mongoid_test_config_development/
        expect(config_text).to match /mongoid_test_config_test/

        Mongoid::Config::Introspection.options(include_deprecated: true).each do |opt|
          if opt.deprecated?
            # deprecated options should not be included
            expect(config_text).not_to include "# #{opt.name}:"
          else
            block = "    #{opt.indented_comment(indent: 4)}\n" \
                    "    # #{opt.name}: #{opt.default}\n"
            expect(config_text).to include block
          end
        end
      end
    end

    it 'generates Mongoid initializer' do
      prepare_new_rails_app 'mongoid-test-init' do
        mongoid_initializer = File.join(TMP_BASE, 'mongoid-test-init/config/initializers/mongoid.rb')

        File.exist?(mongoid_initializer).should be false
        check_call(%w(rails g mongoid:config), env: clean_env)
        File.exist?(mongoid_initializer).should be true
      end
    end
  end

  def install_rails
    check_call(%w(gem uni rails -a))
    if (rails_version = SpecConfig.instance.rails_version) == 'master'
    else
      check_call(%w(gem list))
      check_call(%w(gem install rails --no-document -v) + ["~> #{rails_version}.0"])
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

                  if BSON::Environment.jruby?
                    # Remove existing Gemfile.lock - see
                    # https://github.com/rubygems/rubygems/issues/3231
                    require 'fileutils'
                    FileUtils.rm_f('Gemfile.lock')
                  end

                  check_call(%w(bundle install), env: env)
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

                check_call(%w(bundle exec rake db:mongoid:create_indexes -t),
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

  def clone_application(repo_url, subdir: nil)
    Dir.chdir(TMP_BASE) do
      FileUtils.rm_rf(File.basename(repo_url))
      check_call(%w(git clone) + [repo_url])
      Dir.chdir(File.join(*[File.basename(repo_url), subdir].compact)) do
        adjust_app_gemfile
        adjust_rails_defaults
        check_call(%w(bundle install), env: clean_env)
        puts `git diff`

        write_mongoid_yml

        yield
      end
    end
  end

  def parse_mongodb_uri(uri)
    pre, query = uri.split('?', 2)
    if pre =~ %r,\A(mongodb(?:.*?))://([^/]+)(?:/(.*))?\z,
      protocol = $1
      hosts = $2
      database = $3
      if database == ''
        database = nil
      end
    else
      raise ArgumentError, "Invalid MongoDB URI: #{uri}"
    end
    if query == ''
      query = nil
    end
    {
      protocol: protocol,
      hosts: hosts,
      database: database,
      query: query,
    }
  end

  def build_mongodb_uri(parts)
    "#{parts.fetch(:protocol)}://#{parts.fetch(:hosts)}/#{parts[:database]}?#{parts[:query]}"
  end

  def write_mongoid_yml
    # HACK: the driver does not provide a MongoDB URI parser and assembler,
    # and the Ruby standard library URI module doesn't handle multiple hosts.
    parts = parse_mongodb_uri(SpecConfig.instance.uri_str)
    parts[:database] = 'mongoid_test'
    uri = build_mongodb_uri(parts)
    p uri
    env_config = {'clients' => {'default' => {
      # TODO massive hack, will fail if uri specifies a database name or
      # any uri options
      'uri' => uri,
    }}}
    config = {'development' => env_config, 'production' => env_config}
    File.open('config/mongoid.yml', 'w') do |f|
      f << YAML.dump(config)
    end
  end

  def adjust_app_gemfile(rails_version: SpecConfig.instance.rails_version)
    remove_bundler_req

    gemfile_lines = IO.readlines('Gemfile')
    gemfile_lines.delete_if do |line|
      line =~ /mongoid/
    end
    gemfile_lines << "gem 'mongoid', path: '#{File.expand_path(BASE)}'\n"
    if rails_version
      gemfile_lines.delete_if do |line|
        line =~ /gem ['"]rails['"]/
      end
      if rails_version == 'master'
        gemfile_lines << "gem 'rails', git: 'https://github.com/rails/rails'\n"
      else
        gemfile_lines << "gem 'rails', '~> #{rails_version}.0'\n"
      end
    end
    File.open('Gemfile', 'w') do |f|
      f << gemfile_lines.join
    end
  end

  def adjust_rails_defaults(rails_version: SpecConfig.instance.rails_version)
    if File.exist?('config/application.rb')
      lines = IO.readlines('config/application.rb')
      lines.each do |line|
        line.gsub!(/config.load_defaults \d\.\d/, "config.load_defaults #{rails_version}")
      end
      File.open('config/application.rb', 'w') do |f|
        f << lines.join
      end
    end
  end

  def remove_bundler_req
    return unless File.file?('Gemfile.lock')
    # TODO: Remove this method completely when we get rid of .lock files in
    # mongoid-demo apps.
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
    check_call(%w(bin/spring binstub --remove --all), env: clean_env)
  end

  def clean_env
    @clean_env ||= Hash[ENV.keys.grep(/BUNDLE|RUBYOPT/).map { |k| [k, nil ] }]
  end

  def wait_for_port(port, timeout, process)
    deadline = Mongoid::Utils.monotonic_time + timeout
    loop do
      begin
        Socket.tcp('localhost', port, nil, nil, connect_timeout: 0.5) do |socket|
          return
        end
      rescue IOError, SystemCallError
        unless process.alive?
          raise "Process #{process} died while waiting for port #{port}"
        end
        if Mongoid::Utils.monotonic_time > deadline
          raise
        end
      end
    end
  end
end
