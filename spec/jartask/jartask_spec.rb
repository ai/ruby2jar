require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Ruby2Jar::JarTask do

  it "should add task for create and clobber JAR" do
    task = Ruby2Jar::JarTask.new do |jar|
      jar.name = "app"
    end
    
    Rake::Task["jar"].comment.should == "Build the JAR file pkg/app.jar"
    Rake::Task["clobber_jar"].comment.should == "Remove JAR file pkg/app.jar"
    
    Rake::Task["package"].prerequisites.should include("jar")
    Rake::Task["clobber"].prerequisites.should include("clobber_jar")
  end
  
  it "should set JAR filename by application name and version" do
    task = Ruby2Jar::JarTask.new do |jar|
      jar.name = "MyProgram"
    end
    task.jar.should == "pkg/MyProgram.jar"
    
    task = Ruby2Jar::JarTask.new do |jar|
      jar.name = "MyProgram"
      jar.version = "1.0"
    end
    task.jar.should == "pkg/MyProgram-1.0.jar"
  end
  
  it "shouldn't replace JAR filename if user set it" do
    task = Ruby2Jar::JarTask.new do |jar|
      jar.jar = "some path"
    end
    task.jar.should == "some path"
  end
  
end