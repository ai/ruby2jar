require File.join(File.dirname(__FILE__), "spec_helper")

describe Ruby2Jar::Builder do
  include DirHelper
  
  it "should do all steps and extension functions in order" do
    builder = TracerBuilder.new
    builder.before_copy << lambda {
      builder.steps << "touch"
    }
    
    builder.build
    builder.steps.should == [
      "before_start", "start",
      "before_copy", "touch", "copy",
      "before_create_init", "create_init",
      "before_compile", "compile",
      "before_package", "package",
      "before_finish", "finish"]
  end
  
  it "should can stop finish it work" do
    builder = TracerBuilder.new
    builder.before_create_init << lambda {
      builder.steps << "STOP"
      builder.stop
    }
    
    builder.build
    builder.steps.should == [
      "before_start", "start",
      "before_copy", "copy",
      "before_create_init", "STOP",
      "before_finish", "finish"]
  end
  
  it "should finish it work on exception" do
    builder = TracerBuilder.new
    builder.before_copy << lambda {
      builder.steps << "SHOT"
      raise "Shot"
    }
    builder.before_finish << lambda {
      builder.steps << "HEADSHOT"
      raise "Headshot"
    }
    
    begin
      builder.build
    rescue; end
    builder.steps.should == [
      "before_start", "start",
      "before_copy", "SHOT", "on_error Shot",
      "before_finish", "HEADSHOT", "finish"]
  end
  
  it "should raise error if it doesn't rescue on_error extensions" do
    builder = TracerBuilder.new
    builder.before_start << lambda { raise }
    
    builder.on_error = [lambda { true }]
    builder.method(:build).should_not raise_error
    
    builder.on_error = [lambda { false }]
    builder.method(:build).should raise_error
  end
  
  it "should remember added gems" do
    builder = Ruby2Jar::Builder.new
    builder.add_dependency "one"
    builder.add_dependency "two", ">=0.1", "< 1.0"
    builder.gems.should == [["one", []], ["two", [">=0.1", "< 1.0"]]]
  end
  
  it "should compile all Ruby and Java files" do
    builder = Ruby2Jar::Builder.new
    builder.path = File.join(File.dirname(__FILE__), "fixtures", "app")
    
    builder.before_package << lambda {
      builder.build_dir.should contain_files("ruby/app/main.class", 
        "ruby/app/greeters/english.class", "greeters/JavaGreeter.class")
      builder.stop
    }
    builder.build
  end
  
  it "should create working JAR" do
    builder = Ruby2Jar::Builder.new
    builder.path = File.join(File.dirname(__FILE__), "fixtures", "app")
    builder.main = "main.rb"
    dir = TempDir.create
    builder.include_jruby = true
    builder.jar = File.join(dir, "result.jar")
    builder.build
    
    `java -jar #{builder.jar}`.should == "Hello World!\n"
    
    dir.delete
  end
end