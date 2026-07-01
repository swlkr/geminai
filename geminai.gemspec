require_relative 'lib/geminai/version'

Gem::Specification.new do |spec|
  spec.name          = "geminai"
  spec.version       = Geminai::VERSION
  spec.authors       = ["swlkr"]
  spec.email         = []
  spec.summary       = "Use google's gemini interactions api "
  spec.description   = "A gem for google's gemini interactions api"
  spec.homepage      = "https://github.com/swlkr/geminai"
  spec.license       = "BSD 0 Clause"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files         = Dir["lib/**/*.rb", "README.md"]
  spec.require_paths = ["lib"]
end
