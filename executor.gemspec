# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "executor/version"

Gem::Specification.new do |s|
  s.name        = "executor"
  s.version     = Executor::VERSION
  s.authors     = ["Thomas W. devol"]
  s.email       = ["vajrapani666@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Execute system commands through a configurable interface}
  s.description = %q{Execute system commands with exception handling and logging}

  s.rubyforge_project = "executor"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "nullobject"
  s.add_development_dependency "rspec"
  s.add_development_dependency "em-spec"
end
