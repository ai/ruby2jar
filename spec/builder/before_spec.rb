require File.join(File.dirname(__FILE__), "spec_helper")

describe Ruby2Jar::Builder do
  before :each do
    @builder = Ruby2Jar::Builder.new
    @builder.path = "."
    @builder.include_jruby = false
    @builder.before_copy << lambda { @builder.stop }
  end
  
  it "should set result jar path automatically" do
    tmpdir = TempDir.create
    FileUtils.mkdir File.join(tmpdir, "my_project")
    FileUtils.touch File.join(tmpdir, "my_application.rb")
    
    @builder.path = File.join(tmpdir, "my_project")
    @builder.build
    
    @builder.jar.should == File.join(tmpdir, "my_project", "pkg", "my_project.jar")
    
    @builder.path = File.join(tmpdir, "my_application.rb")
    @builder.jar = nil
    @builder.build
    
    @builder.jar.should == File.join(tmpdir, "my_application.jar")
    
    tmpdir.delete
  end
  
  it "should raise error if path didn't set" do
    @builder.path = nil
    @builder.method(:build).should raise_error(Ruby2Jar::Error, /didn't set path/)
  end
  
  it "should raise error if path isn't exist" do
    nodir = TempDir.new
    
    @builder.path = nodir
    @builder.method(:build).should raise_error(Ruby2Jar::Error, /path is already exist/)
  end
  
  it "should raise error if result jar is already exist" do
    tmpdir = TempDir.create
    FileUtils.touch File.join(tmpdir, "result.jar")
    @builder.jar = File.join(tmpdir, "result.jar")
    
    @builder.method(:build).should raise_error(Ruby2Jar::Error, /jar/)
    
    tmpdir.delete
  end
  
  it "should raise error if main script isn't exist" do
    tmpdir = TempDir.create
    @builder.path = tmpdir
    @builder.main = "script.rb"
    
    @builder.method(:build).should raise_error(Ruby2Jar::Error, /Main script isn't exist/)
    
    FileUtils.touch File.join(tmpdir, "script.rb")
    @builder.method(:build).should_not raise_error(Ruby2Jar::Error)
    
    tmpdir.delete
  end
  
  it "should raise error if it can't find JRuby jar" do
    jruby = ENV['JRUBY_HOME']
    ENV['JRUBY_HOME'] = nil
    @builder.include_jruby = true
    
    @builder.method(:build).should raise_error(Ruby2Jar::Error, /Can't find JRuby/)
    
    ENV['JRUBY_HOME'] = jruby
  end
  
  it "should raise error if JRuby jar isn't exist" do
    @builder.include_jruby = true
    tmpdir = TempDir.new
    @builder.jruby = File.join(tmpdir, "jruby.jar")
    
    @builder.method(:build).should raise_error(Ruby2Jar::Error, /JRuby isn't exist/)
  end
  
  it "should find JRuby jar by JRUBY_HOME enviroment" do
    jruby = ENV['JRUBY_HOME']
    ENV['JRUBY_HOME'] = File.join(File.dirname(__FILE__), "fixtures", "jruby")
    @builder.include_jruby = true
    
    @builder.build
    @builder.jruby.should == File.join(ENV['JRUBY_HOME'], "lib", "jruby.jar")
    
    ENV['JRUBY_HOME'] = jruby
  end
  
  it "should create temporal dir on start and delete it on finish " do
    @build_dir = nil
    @builder.before_copy << lambda {
      @build_dir = @builder.build_dir
      @build_dir.should_not be_nil
      File.directory?(@build_dir).should be_true
    }
    
    @builder.build
    File.directory?(@build_dir).should be_false
  end
end
