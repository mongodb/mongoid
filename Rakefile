# frozen_string_literal: true

require "bundler"
Bundler.setup

ROOT = File.expand_path(File.join(File.dirname(__FILE__)))

$: << File.join(ROOT, 'spec/shared/lib')

require "rake"
require "rspec/core/rake_task"

if File.exist?('./spec/shared/lib/tasks/candidate.rake')
  load 'spec/shared/lib/tasks/candidate.rake'
end

desc 'Build the gem'
task :build do
  command = %w[ gem build ]
  command << "--output=#{ENV['GEM_FILE_NAME']}" if ENV['GEM_FILE_NAME']
  command << (ENV['GEMSPEC'] || 'mongoid.gemspec')
  system(*command)
end

# `rake version` is used by the deployment system so get the release version
# of the product beng deployed. It must do nothing more than just print the
# product version number.
# 
# See the mongodb-labs/driver-github-tools/ruby/publish Github action.
desc "Print the current value of Mongoid::VERSION"
task :version do
  require 'mongoid/version'

  puts Mongoid::VERSION
end

# overrides the default Bundler-provided `release` task, which also
# builds the gem. Our release process assumes the gem has already
# been built (and signed via GPG), so we just need `rake release` to
# push the gem to rubygems.
task :release do
  require 'mongoid/version'

  if ENV['GITHUB_ACTION'].nil?
    abort <<~WARNING
      `rake release` must be invoked from the `Mongoid Release` GitHub action,
      and must not be invoked locally. This ensures the gem is properly signed
      and distributed by the appropriate user.

      Note that it is the `rubygems/release-gem@v1` step in the `Mongoid Release`
      action that invokes this task. Do not rename or remove this task, or the
      release-gem step will fail. Reimplement this task with caution.

      mongoid-#{Mongoid::VERSION}.gem was NOT pushed to RubyGems.
    WARNING
  end

  system 'bundle', 'exec', 'gem', 'push', "mongoid-#{Mongoid::VERSION}.gem"
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
  require 'mrss/spec_organizer'

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
    require "mongoid/version"

    out = File.join('yard-docs', Mongoid::VERSION)
    FileUtils.rm_rf(out)
    system "yardoc -o #{out} --title mongoid-#{Mongoid::VERSION}"
  end
end
