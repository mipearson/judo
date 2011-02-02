# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{judo}
  s.version = "0.5.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Orion Henry"]
  s.date = %q{2011-02-01}
  s.default_executable = %q{judo}
  s.description = %q{The gentle way to manage and control ec2 instances}
  s.email = %q{orion@heroku.com}
  s.executables = ["judo"]
  s.extra_rdoc_files = [
    "README.markdown"
  ]
  s.files = [
    "README.markdown",
    "Rakefile",
    "VERSION",
    "bin/judo",
    "default/config.json",
    "default/example_config.erb",
    "default/setup.sh",
    "default/userdata.erb",
    "lib/judo.rb",
    "lib/judo/base.rb",
    "lib/judo/cli_helpers.rb",
    "lib/judo/group.rb",
    "lib/judo/patch.rb",
    "lib/judo/server.rb",
    "lib/judo/snapshot.rb",
    "lib/judo/util.rb"
  ]
  s.homepage = %q{http://github.com/orionz/judo}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{judo}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{The gentle way to manage and control ec2 instances}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<aws>, [">= 2.4.0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_runtime_dependency(%q<rainbow>, [">= 0"])
    else
      s.add_dependency(%q<aws>, [">= 2.4.0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<rainbow>, [">= 0"])
    end
  else
    s.add_dependency(%q<aws>, [">= 2.4.0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<rainbow>, [">= 0"])
  end
end

