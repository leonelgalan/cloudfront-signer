# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "aws-cf-signer/version"

Gem::Specification.new do |s|
  s.name        = "aws-cf-signer"
  s.version     = AWS::CF::VERSION
  s.authors     = ["Anthony Bouch"]
  s.email       = ["tony@58bits.com"]
  s.homepage    = "http://github.com/58bits/aws-cf-signer"
  s.summary     = %q{A gem to sign stream paths and urls for CloudFront private content.}
  s.description = %q{A fork of Dylan Vaughn's excellent signing gem - https://github.com/stlondemand/aws_cf_signer.}

  s.rubyforge_project = "aws-cf-signer"

  s.add_development_dependency "rspec" 

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
