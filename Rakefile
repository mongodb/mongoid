# frozen_string_literal: true

require "bundler"
require "bundler/gem_tasks"
Bundler.setup

ROOT = File.expand_path(File.join(File.dirname(__FILE__)))

$: << File.join(ROOT, 'spec/shared/lib')

require "rake"
require "rspec/core/rake_task"
require 'mrss/spec_organizer'
require 'rubygems/package'
require 'rubygems/security/policies'

def signed_gem?(path_to_gem)
  Gem::Package.new(path_to_gem, Gem::Security::HighSecurity).verify
  true
rescue Gem::Security::Exception => e
  false
end

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "mongoid/version"

tasks = Rake.application.instance_variable_get('@tasks')
tasks['release:do'] = tasks.delete('release')

task :gem => :build
task :build do
  system "gem build mongoid.gemspec"
end

task :install => :build do
  system "sudo gem install mongoid-#{Mongoid::VERSION}.gem"
end

task :release do
  raise "Please use ./release.sh to release"
end

RSpec::Core::RakeTask.new("spec") do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

RSpec::Core::RakeTask.new('spec:progress') do |spec|
  spec.rspec_opts = %w(--format progress)
  spec.pattern = "spec/**/*_spec.rb"
end

CLASSIFIERS = [
  [%r,^mongoid/attribute,, :attributes],
  [%r,^mongoid/association/[or],, :associations_referenced],
  [%r,^mongoid/association,, :associations],
  [%r,^mongoid,, :unit],
  [%r,^integration,, :integration],
  [%r,^rails,, :rails],
]

RUN_PRIORITY = %i(
  unit attributes associations_referenced associations
  integration rails
)

def spec_organizer
  Mrss::SpecOrganizer.new(
    root: ROOT,
    classifiers: CLASSIFIERS,
    priority_order: RUN_PRIORITY,
  )
end

task :ci do
  spec_organizer.run
end

task :bucket, %i(buckets) do |task, args|
  buckets = args[:buckets]
  buckets = if buckets.nil? || buckets.empty?
    [nil]
  else
    buckets.split(':').map do |bucket|
      if bucket.empty?
        nil
      else
        bucket.to_sym
      end
    end
  end
  spec_organizer.run_buckets(*buckets)
end

task :default => :spec

desc "Generate all documentation"
task :docs => 'docs:yard'

namespace :docs do
  desc "Generate yard documention"
  task :yard do
    out = File.join('yard-docs', Mongoid::VERSION)
    FileUtils.rm_rf(out)
    system "yardoc -o #{out} --title mongoid-#{Mongoid::VERSION}"
  end
end

namespace :release do
  task :check_private_key do
    unless File.exist?('gem-private_key.pem')
      raise "No private key present, cannot release"
    end
  end
end

desc 'Verifies that all built gems in pkg/ are valid'
task :verify do
  gems = Dir['pkg/*.gem']
  if gems.empty?
    puts 'There are no gems in pkg/ to verify'
  else
    gems.each do |gem|
      if signed_gem?(gem)
        puts "#{gem} is signed"
      else
        abort "#{gem} is not signed"
      end
    end
  end
end
