$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "amazon-textract-parser-ruby"
require "minitest/reporters"
Minitest::Reporters.use!
require "minitest/autorun"
