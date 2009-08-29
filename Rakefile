require "rubygems"
require "rake"
require "rake/rdoctask"
require "spec/rake/spectask"
require "metric_fu"

begin
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.name = "mongoloid"
    gem.summary = %Q{Mongoloid}
    gem.email = "durran@gmail.com"
    gem.homepage = "http://github.com/durran/mongoloid"
    gem.authors = ["Durran Jordan"]
  end

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << "lib" << "spec"
  spec.spec_files = FileList["spec/**/*_spec.rb"]
  spec.spec_opts = ['--options', "spec/spec.opts"]
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << "lib" << "spec"
  spec.pattern = "spec/**/*_spec.rb"
  spec.rcov = true
end

Rake::RDocTask.new do |rdoc|
  if File.exist?("VERSION.yml")
    config = YAML.load(File.read("VERSION.yml"))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end
  rdoc.rdoc_dir = "rdoc"
  rdoc.title = "my_emma #{version}"
  rdoc.rdoc_files.include("README*")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

task :default => "metrics:all"