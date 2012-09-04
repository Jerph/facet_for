# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "facet_for/version"

Gem::Specification.new do |s|
  s.name        = "facet_for"
  s.version     = FacetFor::VERSION
  s.authors     = ["Jonathan Barket"]
  s.email       = ["jbarket@sleepunit.com"]
  s.homepage    = ""
  s.summary     = %q{Provides helpers for creating search forms with Ransack}
  s.description = %q{Provides helpers for creating search forms with Ransack}

  s.rubyforge_project = "facet_for"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "ransack"
end
