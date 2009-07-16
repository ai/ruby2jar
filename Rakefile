require 'rubygems'
require 'rake'
require "rake/rdoctask"
require 'spec/rake/spectask'
require 'rake/gempackagetask'

require File.join(File.dirname(__FILE__), "lib", "ruby2jar")

##############################################################################
# Tests
##############################################################################

desc "Run all specs"
Spec::Rake::SpecTask.new('specs') do |t|
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.spec_files = Dir['spec/**/*_spec.rb'].sort
end

desc "Run a specific spec with TASK=xxxx"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.libs = ['lib']
  t.spec_files = ["spec/**/#{ENV['TASK']}_spec.rb"]
end

desc "Run all specs output html"
Spec::Rake::SpecTask.new('specs_html') do |t|
  t.spec_opts = ["--format", "html"]
  t.libs = ['lib']
  t.spec_files = Dir['spec/**/*_spec.rb'].sort
end

desc "RCov"
Spec::Rake::SpecTask.new('rcov') do |t|
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.spec_files = Dir['spec/**/*_spec.rb'].sort
  t.libs = ['lib']
  t.rcov = true
end

##############################################################################
# Documentation and distribution
##############################################################################

Rake::RDocTask.new do |rdoc|
  rdoc.main = "README"
  rdoc.rdoc_files.include("README", "LICENSE", "lib/**/*.rb")
  rdoc.title = "Ruby2Jar docs"
  rdoc.rdoc_dir = "doc"
  rdoc.options << "--all"
end

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = "ruby2jar"
  s.version = "0.1"
  s.summary = "Build JAR from Ruby script."
  s.description = <<-EOF
    Ruby2Jar build JAR from Ruby script. It copy gems, compile sources and 
    package JAR. It is a easy way to distribute your JRuby application or to 
    create Applet or Java Web Start.
  EOF
  
  s.files = FileList[
    "lib/**/*", 
    "spec/**/*",
    "LICENSE",
    "TODO",
    "Rakefile",
    "README"]
  s.require_path = 'lib'
  
  s.add_dependency 'rake'
  
  s.author = 'Andrey "A.I." Sitnik'
  s.email = "andrey@sitnik.ru"
  s.homepage = "http://ruby2jar.rubyforge.org/"
  s.rubyforge_project = "ruby2jar"
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end