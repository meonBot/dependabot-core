# frozen_string_literal: true

require "./lib/dependabot/version"

Gem::Specification.new do |spec|
  spec.name         = "dependabot-core"
  spec.version      = Dependabot::VERSION
  spec.summary      = "Automated dependency management"
  spec.description  = "Automated dependency management for Ruby, JavaScript, "\
                      "Python, PHP, Elixir, Rust, Java, .NET, Elm and Go"

  spec.author       = "Dependabot"
  spec.email        = "support@dependabot.com"
  spec.homepage     = "https://github.com/hmarr/dependabot-core"
  spec.license      = "License Zero Prosperity Public License"

  spec.require_path = "lib"
  spec.files        = Dir["CHANGELOG.md", "LICENSE.txt", "README.md",
                          "lib/**/*", "helpers/**/*"]

  spec.required_ruby_version = ">= 2.5.0"
  spec.required_rubygems_version = ">= 2.7.3"

  spec.add_dependency "aws-sdk-ecr", "~> 1.5"
  spec.add_dependency "bundler", "~> 1.16"
  spec.add_dependency "docker_registry2", "~> 1.4.1"
  spec.add_dependency "excon", "~> 0.55"
  spec.add_dependency "gitlab", "~> 4.1"
  spec.add_dependency "gpgme", "~> 2.0"
  spec.add_dependency "nokogiri", "~> 1.8"
  spec.add_dependency "octokit", "~> 4.6"
  spec.add_dependency "parseconfig", "~> 1.0"
  spec.add_dependency "parser", "~> 2.5"
  spec.add_dependency "toml-rb", "~> 1.1", ">= 1.1.2"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.8.0"
  spec.add_development_dependency "rspec-its", "~> 1.2.0"
  spec.add_development_dependency "rubocop", "~> 0.59.0"
  spec.add_development_dependency "vcr", "~> 4.0.0"
  spec.add_development_dependency "webmock", "~> 3.4.0"
end
