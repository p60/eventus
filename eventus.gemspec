# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "eventus/version"

Gem::Specification.new do |s|
  s.name        = "eventus"
  s.version     = Eventus::VERSION
  s.authors     = ["Jason Staten"]
  s.email       = ["jstaten07@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Event Store}
  s.description = %q{An Event Store}

  s.rubyforge_project = "eventus"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "sequel"
  s.add_runtime_dependency "ffi-rzmq"
end
