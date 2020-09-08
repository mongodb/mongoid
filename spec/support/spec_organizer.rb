require 'support/child_process_helper'

autoload :FileUtils, 'fileutils'
autoload :Find, 'find'

# Organizes and runs all of the tests in the test suite in batches.
#
# Organizing the tests in batches serves two purposes:
#
# 1. This allows running unit tests before integration tests, therefore
#    in theory revealing failures quicker on average.
# 2. This allows running some tests that have high intermittent failure rate
#    in their own test process.
#
# This class aggregates RSpec results after the test runs.
class SpecOrganizer
  CLASSIFIERS = [
    [%r,^mongoid,, :unit],
    [%r,^mongoid/associations,, :associations],
    [%r,^integration,, :integration],
    [%r,^rails,, :rails],
  ]

  RUN_PRIORITY = %i(unit
    associations integration rails
  )

  SPEC_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  ROOT = File.expand_path(File.join(SPEC_ROOT, '..'))
  RSPEC_JSON_PATH = File.join(ROOT, 'tmp/rspec.json')
  RSPEC_ALL_JSON_PATH = File.join(ROOT, 'tmp/rspec-all.json')

  def run
    FileUtils.rm_f(RSPEC_ALL_JSON_PATH)

    buckets = {}
    Find.find(SPEC_ROOT) do |path|
      next unless File.file?(path)
      next unless path =~ /_spec\.rb\z/
      rel_path = path[(SPEC_ROOT.length + 1)..path.length]

      found = false
      CLASSIFIERS.each do |(regexp, category)|
        if regexp =~ rel_path
          buckets[category] ||= []
          buckets[category] << rel_path
          found = true
          break
        end
      end

      unless found
        buckets[nil] ||= []
        buckets[nil] << rel_path
      end
    end

    failed = []

    RUN_PRIORITY.each do |category|
      if files = buckets.delete(category)
        unless run_files(category, files)
          failed << category
        end
      end
    end
    if files = buckets.delete(nil)
      unless run_files('remaining', files)
        failed << 'remaining'
      end
    end

    unless buckets.empty?
      raise "Some buckets were not executed: #{buckets.keys.map(&:to_s).join(', ')}"
    end

    if failed.any?
      raise "The following buckets failed: #{failed.map(&:to_s).join(', ')}"
    end
  end

  def run_files(category, paths)
    paths = paths.map do |path|
      File.join('spec', path)
    end

    puts "Running #{category.to_s.gsub('_', ' ')} tests"
    FileUtils.rm_f(RSPEC_JSON_PATH)
    cmd = %w(rspec) + paths

    begin
      ChildProcessHelper.check_call(cmd)
    ensure
      if File.exist?(RSPEC_JSON_PATH)
        if File.exist?(RSPEC_ALL_JSON_PATH)
          merge_rspec_results
        else
          FileUtils.cp(RSPEC_JSON_PATH, RSPEC_ALL_JSON_PATH)
        end
      end
    end

    true
  rescue ChildProcessHelper::SpawnError
    false
  end

  def merge_rspec_results
    all = JSON.parse(File.read(RSPEC_ALL_JSON_PATH))
    new = JSON.parse(File.read(RSPEC_JSON_PATH))
    all['examples'] += new.delete('examples')
    new.delete('summary').each do |k, v|
      all['summary'][k] += v
    end
    new.delete('version')
    new.delete('summary_line')
    unless new.empty?
      raise "Unhandled rspec results keys: #{new.keys.join(', ')}"
    end
    # We do not merge summary lines, delete them from aggregated results
    all.delete('summary_line')
    File.open(RSPEC_ALL_JSON_PATH, 'w') do |f|
      f << JSON.dump(all)
    end
  end
end
