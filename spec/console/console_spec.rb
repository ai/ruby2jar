require File.join(File.dirname(__FILE__), "..", "spec_helper")

require "tempfile"

describe Ruby2Jar::Console do
  before :each do
    @console = Ruby2Jar::Console.new
    @real_stderr = STDERR.clone
    @errors = Tempfile.new "ruby2jar_test_stderr"
    STDERR.reopen(@errors)
  end
  
  it "should print message from exception in STDERR" do
    @console.on_error(Ruby2Jar::Error.new("ERROR_MSG"))
    @errors.rewind
    @errors.read.should include("ERROR_MSG")
  end
  
  it "shouldn't catch non-builder exceptions" do
    @console.on_error(Ruby2Jar::Error.new).should be_true
    @console.on_error(Exception.new).should be_false
  end
  
  after :each do
    STDERR.reopen(@real_stderr)
  end
end