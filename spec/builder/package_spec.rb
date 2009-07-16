require File.join(File.dirname(__FILE__), "spec_helper")

describe Ruby2Jar::Builder do
  include DirHelper
  
  before :each do
    @builder = Ruby2Jar::Builder.new
    @builder.include_jruby = false
    @app_path = TempDir.create
    @result_path = TempDir.create
    @builder.path = @app_path
    @builder.jar = File.join(@result_path, "result.jar")
  end
  
  it "should package all files to JAR" do
    create_files @builder.path, ["one.class", "subdir/two.class"]
    
    @builder.build
    @builder.jar.should contain_files(
      "ruby/app/one.class", "ruby/app/subdir/two.class", "META-INF/MANIFEST.MF")
  end
  
  it "should copy JRuby classes if it neccessary" do
    @builder.include_jruby = true
    @builder.jruby = File.join(File.expand_path(File.dirname(__FILE__)), 
      "fixtures", "jruby", "lib", "jruby.jar")
    
    @builder.build
    @builder.jar.should contain_files("jruby.class", "META-INF/MANIFEST.MF")
  end
  
  it "should add manifest if it neccessary" do
    @builder.create_manifest = true
    @builder.manifest["test"] = "value"
    
    @builder.build
    dir = TempDir.create
    current = Dir.getwd
    Dir.chdir dir
        
    `jar -xf #{@builder.jar}`
    IO.read("META-INF/MANIFEST.MF").should include("test: value")
        
     Dir.chdir current
     dir.delete
  end
  
  after :each do
    @app_path.delete
    @result_path.delete
  end
end