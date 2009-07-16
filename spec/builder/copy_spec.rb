require File.join(File.dirname(__FILE__), "spec_helper")

describe Ruby2Jar::Builder do
  include DirHelper
  
  before :each do
    @builder = Ruby2Jar::Builder.new
    @builder.include_jruby = false
    @app_path = TempDir.create
    @builder.path = @app_path
    @builder.before_create_init << lambda { @builder.stop }
    @builder.gems_index = FakeGems.new
  end
  
  it "should copy all neccessary file from application dir" do
    create_files @builder.path, ["1.rb", "1.no", "subdir/2.rb", "subdir/3.rb"]
    Dir.chdir(@builder.path) do
      @builder.files = FileList["**/*"].exclude("*.no")
    end
    
    @builder.before_create_init << lambda {
      @builder.build_dir.should contain_files(
        "ruby/app/1.rb", "ruby/app/subdir/2.rb", "ruby/app/subdir/3.rb")
    }
    @builder.build
  end
  
  it "should copy file if application is a one script" do
    create_files @builder.path, "application.rb"
    @builder.path = File.join(@builder.path, "application.rb")
    
    @builder.before_create_init << lambda {
      @builder.build_dir.should contain_files("ruby/app/application.rb")
    }
    @builder.build
  end
  
  it "should copy all Java file to archive root" do
    create_files @builder.path, ["one.rb", "ext/subdir/pure.java"]
    
    @builder.before_create_init << lambda {
      @builder.build_dir.should contain_files("ruby/app/one.rb", "subdir/pure.java")
    }
    @builder.build
  end
  
  it "should delete java source file if compiled class file if already exist" do
    create_files @builder.path, ["one.rb", "ext/pure.java", "ext/pure.class"]
    
    @builder.before_create_init << lambda {
      @builder.build_dir.should contain_files("ruby/app/one.rb", "pure.class")
    }
    @builder.build
  end
  
  it "should raise error if gem isn't found" do
    @builder.gems_index.gems = {}
    @builder.add_dependency "gem"
    @builder.method(:build).should raise_error(Ruby2Jar::Error, /Can't find gem/)
  end
  
  it "should raise error if gem with different version is already added" do
    @builder.gems_index.gems = {
      "gem-1.0" => FakeSpecification.new("gem", "1.0", @builder.path),
      "gem-0.9" => FakeSpecification.new("gem", "0.9", @builder.path)}
    @builder.add_dependency "gem", "1.0"
    @builder.add_dependency "gem", "0.9"
    
    @builder.method(:build).should raise_error(Ruby2Jar::Error, /different version/)
  end
  
  it "should copy gem dependencies too" do
    
    @builder.gems_index.gems = {
      "one-" => FakeSpecification.new("one", "", @builder.path, ["two"]), 
      "two-" => FakeSpecification.new("two", "", @builder.path, ["one"])}
    @builder.add_dependency "one"
    
    @builder.before_create_init << lambda {
      @builder.loaded_gems.should == ["one", "two"]
    }
    @builder.build
  end
  
  it "should load java config from gem" do
    gem_path = TempDir.create
    File.open(File.join(gem_path, "java.yaml"), "w") do |file|
      file.write({"name" => "value"}.to_yaml)
    end
    @builder.gems_index.gems = {
      "gem-" => FakeSpecification.new("gem", "", gem_path)}
    @builder.add_dependency "gem"
    
    @builder.before_create_init << lambda {
      @builder.configs["gem"].should == {"name" => "value"}
    }
    @builder.build
    
    gem_path.delete
  end
  
  it "should copy all neccessary file from gem dir" do
    gem_path = TempDir.create
    create_files gem_path, ["one.rb", "1.no", "subdir/two.rb", "ext/pure.java"]
    File.open(File.join(gem_path, "java.yaml"), "w") do |file|
      file.write({"jar" => {"exclude" => "*.no"}}.to_yaml)
    end
    @builder.gems_index.gems = {
      "gem-" => FakeSpecification.new("gem", "", gem_path)}
    @builder.add_dependency "gem"
    
    @builder.before_create_init << lambda {
      @builder.build_dir.should contain_files(
        "ruby/gems/gem/one.rb", "ruby/gems/gem/subdir/two.rb", "pure.java")
    }
    @builder.build
    
    gem_path.delete
  end
  
  it "should add gem and app paths to init_require_paths" do
    @builder.gems_index.gems = {
      "gem-" => FakeSpecification.new("gem", "", @builder.path)}
    @builder.add_dependency "gem"
    @builder.require_paths = ["one", "two"]
    
    @builder.before_create_init << lambda {
      @builder.init_require_paths.should include("ruby/gems/gem/lib")
      @builder.init_require_paths.should include("ruby/app/one")
      @builder.init_require_paths.should include("ruby/app/two")
    }
    @builder.build
  end
  
  after :each do
    @app_path.delete
  end
end