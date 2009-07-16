require File.join(File.dirname(__FILE__), "..", "spec_helper")

require "tmpdir"
require "fileutils"

class TracerBuilder < Ruby2Jar::Builder
  attr_accessor :steps
  def initialize
    super
    @steps = []
    @before_start       << lambda { self.steps << "before_start" }
    @before_copy        << lambda { self.steps << "before_copy" }
    @before_create_init << lambda { self.steps << "before_create_init" }
    @before_compile     << lambda { self.steps << "before_compile" }
    @before_package     << lambda { self.steps << "before_package" }
    @before_finish      << lambda { self.steps << "before_finish" }
    @on_error << lambda { |error| self.steps << "on_error #{error}"; false }
  end
  def start
    @steps << "start"
  end
  def copy
    @steps << "copy"
  end
  def create_init
    @steps << "create_init"
  end
  def compile
    @steps << "compile"
  end
  def package
    @steps << "package"
  end
  def finish
    @steps << "finish"
  end
end

class TempDir < String
  def self.create
    dir = self.new
    Dir.mkdir dir
    dir
  end
  def initialize
    number = Time.now.to_i
    begin
      number += 1
      tmpdir = File.join(Dir.tmpdir, "ruby2jar_test_#{number}")
    end while File.exist? tmpdir
    self.replace tmpdir
  end
  def delete
    FileUtils.rm_r self
  end
end

class FakeGems
  attr_accessor :gems
  def find_name(gem, version)
    @gems["#{gem}-#{version}"].to_a
  end
end

class FakeSpecification
  attr_accessor :name, :full_name, :full_gem_path, :require_paths, :dependencies
  def initialize(name, version, path, dependencies = [])
    @name = name
    @full_name = "#{name}-#{version}"
    @full_gem_path = path
    @require_paths = "lib"
    @dependencies = dependencies
  end
  def to_a
    [self]
  end
end

module DirHelper
  class ContainFiles
    def initialize(files)
      @files = files.sort
    end
    def files(dir)
      Dir.glob(File.join(dir, "**", "*")).delete_if { |i| File.directory? i }.map { |i| i[dir.length+1..-1] }.sort
    end
    def matches?(path)
      @path = path
      if File.directory? @path
        @in_dir = files @path
      elsif ".jar" == File.extname(@path)
        dir = TempDir.create
        current = Dir.getwd
        Dir.chdir dir
        
        `jar -xf #{@path}`
        @in_dir = files dir
        
        Dir.chdir current
        dir.delete
      end
      @in_dir == @files
    end
    def failure_message
      "in #{@path} expected files [#{@files.join(", ")}], but found [#{@in_dir.join(", ")}]"
    end
    def negative_failure_message
      "in #{@path} doesn't expected files [#{@files.join(", ")}], but it does"
    end
  end
  def contain_files(*files)
    ContainFiles.new(files)
  end
  def create_files(dir, files)
    files.each do |file|
      file = File.join(dir, file)
      FileUtils.makedirs File.dirname(file)
      FileUtils.touch file
    end
  end
end