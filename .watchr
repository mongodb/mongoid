def run(cmd)
  puts cmd
  system cmd
end

def spec(file)
  run "spec -O spec/spec.opts #{file}"
end

watch("spec/.*/*_spec\.rb")  {|md| p md[0]; spec(md[0]) }
watch('lib/(.*/.*)\.rb')     {|md| p md[1]; spec("spec/unit/#{md[1]}_spec.rb") }
