# vim:set filetype=ruby:
guard(
  "rspec",
  :all_after_pass => false,
  :cli => "--fail-fast --tty --format documentation --colour") do

  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) do |match|
    [
      "spec/functional/#{match[1]}_spec.rb" ,
      "spec/unit/#{match[1]}_spec.rb"
    ]
  end
end
