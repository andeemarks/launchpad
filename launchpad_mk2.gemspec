# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "launchpad_mk2/version"

Gem::Specification.new do |s|
  s.name        = "launchpad_mk2"
  s.version     = LaunchpadMk2::VERSION
  s.authors     = ["Andy Marks"]
  s.email       = ["vampwillow@gmail.com"]
  s.homepage    = "https://github.com/andeemarks/launchpad"
  s.summary     = %q{A Ruby gem for programmatically controlling the Novation Launchpad MK2.}
  s.description = %q{This gem provides programmatic access to the Novation Launchpad MK2. LEDs can be lighted and button presses can be evaluated using launchpad's MIDI input/output.}
  s.license     = 'MIT'
  s.rubyforge_project = "launchpad_mk2"

  s.add_dependency "portmidi", "= 0.0.6"
  s.add_dependency "ffi", "= 1.9.18"
  s.add_development_dependency "rake", "~> 12"
  if RUBY_VERSION < "1.9"
    s.add_development_dependency "minitest"
  else
    s.add_development_dependency "minitest-reporters", "~> 1.1", ">= 1.1.14"
  end
  s.add_development_dependency "mocha", "~> 0.14", ">= 0.14.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
