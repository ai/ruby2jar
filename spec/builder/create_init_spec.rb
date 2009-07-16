require File.join(File.dirname(__FILE__), "spec_helper")

describe Ruby2Jar::Builder do
  before :each do
    @builder = Ruby2Jar::Builder.new
    @builder.include_jruby = false
    @app_path = TempDir.create
    @builder.path = @app_path
    @builder.before_compile << lambda { @builder.stop }
    FileUtils.touch File.join(@builder.path, "main.rb")
    @builder.main = "main.rb"
  end
  
  it "should create init script" do
    @builder.before_compile << lambda { 
      File.exist?(File.join(@builder.build_dir, "ruby", "init.rb")).should be_true
    }
    @builder.build
  end
  
  it "should create init script with gem and require methods and calling main" do
    @builder.before_compile << lambda {
      init = IO.read File.join(@builder.build_dir, "ruby", "init.rb")
      init.should include('def gem')
      init.should include('def require')
      init.should include('require "ruby/app/main"')
    }
    @builder.build
  end
  
  it "should add init_require_paths to LOAD_PATH in init script" do
    @builder.before_create_init << lambda { 
      @builder.init_require_paths = ["one", "two/subdir"]
    }
    @builder.before_compile << lambda {
      init = IO.read File.join(@builder.build_dir, "ruby", "init.rb")
      init.should include('$LOAD_PATH << "one"')
      init.should include('$LOAD_PATH << "two/subdir"')
    }
    @builder.build
  end
  
  it "shouldn't do any action if main script isn't set" do
    @builder.main = nil
    @builder.before_compile << lambda {
      File.exist?(File.join(@builder.build_dir, "ruby", "init.rb")).should be_false
    }
    @builder.build
  end
  
  it "should add init script as Main-Class to manifest" do
    @builder.before_compile << lambda {
      @builder.manifest["Main-Class"].should == "ruby.init"
    }
    @builder.build
  end
  
  it "shouldn't replace Main-Class in manifest" do
    @builder.manifest["Main-Class"] = "test"
    @builder.before_compile << lambda {
      @builder.manifest["Main-Class"].should == "test"
    }
    @builder.build
  end
  
  after :each do
    @app_path.delete
  end
end