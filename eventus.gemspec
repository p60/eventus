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

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~>2.0'
  s.add_development_dependency 'uuid'
  s.add_development_dependency 'mongo'
  s.add_development_dependency 'bson_ext'
  s.add_development_dependency 'redis'
  s.add_development_dependency 'sequel'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'sequel-enhancements'
end
