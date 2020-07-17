
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "amazon-textract-parser-ruby/version"

Gem::Specification.new do |spec|
  spec.name          = "amazon-textract-parser-ruby"
  spec.version       = AmazonTRP::VERSION
  spec.authors       = ["Niels Vanspauwen"]
  spec.email         = ["niels.vanspauwen@gmail.com"]

  spec.summary       = %q{Amazon Textract Results Parser}
  spec.description   = %q{This is a quick Ruby port of https://github.com/mludvig/amazon-textract-parser\nIt's useful for interpreting the result of Amazon Textract info.}
  spec.homepage      = "https://github.com/nielsvanspauwen/amazon-textract-parser-ruby"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 12.3.3"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "activesupport", "~> 6.0.3.2"
end
