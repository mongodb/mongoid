CPUPROFILE_REALTIME=1 bundle exec ruby perf/profile.rb

bundle exec pprof.rb --pdf perf/mongoid_profile_insert > perf/reports/insert.pdf
bundle exec pprof.rb --pdf perf/mongoid_profile_query > perf/reports/query.pdf
bundle exec pprof.rb --pdf perf/mongoid_profile_update > perf/reports/update.pdf
