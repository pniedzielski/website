# coding: utf-8
task :default => :build

require 'jekyll'

desc 'Clean up generated site'
task :clean do
  Jekyll::Commands::Clean.process({})
end

desc 'Generate non-production version of the site'
task :build do
  Jekyll::Commands::Build.process(profile: true)
end

desc 'Generate production version of the site'
task :buildproduction do
  ENV["JEKYLL_ENV"] = "production"
  Jekyll::Commands::Build.process(profile: true)
end
