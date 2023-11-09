# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in anony.gemspec
gemspec

gem "activerecord", "~> #{ENV['RAILS_VERSION']}" if ENV["RAILS_VERSION"]
gem "activesupport", "~> #{ENV['RAILS_VERSION']}" if ENV["RAILS_VERSION"]

gem "bundler", "~> 2", :group => :development
gem "gc_ruboconfig", "~> 3.6.0", :group => :development
gem "rspec", "~> 3.9", :group => :development
gem "rspec-github", "~> 2.4.0", :group => :development
gem "yard", "~> 0.9.20", :group => :development

# For integration testing
gem "sqlite3", "~> 1.6.1", :group => :development
