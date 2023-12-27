# frozen_string_literal: true

require_relative "lib/claret/version"

Gem::Specification.new do |spec|
  spec.name = "claret"
  spec.version = Claret::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]

  spec.summary = "A Ruby dialect that includes types in the language. Transpiles to Ruby and RBS."
  spec.description = "A Ruby dialect that includes types in the language. Transpiles to Ruby and RBS."
  spec.homepage = "https://github.com/stevegeek/claret"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/stevegeek/claret"
  spec.metadata["changelog_uri"] = "https://github.com/stevegeek/claret/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "ruby-next", "~> 1.0"
  spec.add_dependency "steep", "~> 1.6"
  spec.add_dependency "irbs", "> 0.1", "< 1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
