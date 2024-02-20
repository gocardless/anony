# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in anony.gemspec
gemspec

gem "activerecord", "~> #{ENV['RAILS_VERSION']}" if ENV["RAILS_VERSION"]
gem "activesupport", "~> #{ENV['RAILS_VERSION']}" if ENV["RAILS_VERSION"]
