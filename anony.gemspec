# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "anony/version"

Gem::Specification.new do |spec|
  spec.name          = "anony"
  spec.version       = Anony::VERSION
  spec.authors       = ["GoCardless Engineering"]
  spec.email         = ["engineering@gocardless.com"]

  spec.summary       = "A small library that defines how ActiveRecord models should be " \
                       "anonymised for deletion purposes."
  spec.homepage      = "https://github.com/gocardless/anony"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.1"

  if ENV["RAILS_VERSION"]
    spec.add_dependency "activerecord", "~> #{ENV['RAILS_VERSION']}"
    spec.add_dependency "activesupport", "~> #{ENV['RAILS_VERSION']}"
  else
    spec.add_dependency "activerecord", ">= 7.0", "< 9"
    spec.add_dependency "activesupport", ">= 7.0", "< 9"
  end
  spec.metadata["rubygems_mfa_required"] = "true"
end
