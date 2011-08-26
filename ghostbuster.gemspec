# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ghostbuster/version"

Gem::Specification.new do |s|
  s.name        = "ghostbuster"
  s.version     = Ghostbuster::VERSION
  s.authors     = ["Josh Hull"]
  s.email       = ["joshbuddy@gmail.com"]
  s.homepage    = "https://github.com/joshbuddy/ghostbuster"
  s.summary     = %q{Integration testing ftw}
  s.description = %q{Integration testing ftw.}

  s.rubyforge_project = "ghostbuster"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'thin',    '~> 1.2.11'
  s.add_development_dependency 'rake',    '~> 0.8.7'
  s.add_development_dependency 'bundler', '~> 1.0.14'
  s.add_development_dependency 'sinatra'
end
