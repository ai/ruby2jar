require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Ruby2Jar::Listener do

  it "should add before_* functions as builder listeners" do
    three_proc = lambda {}
    
    class Builder1
      attr_accessor :before_one
      attr_accessor :before_two
      attr_accessor :before_three
    end
    builder = Builder1.new
    builder.before_one = []
    builder.before_two = []
    builder.before_three = [three_proc]
    
    class Listener1 < Ruby2Jar::Listener
      def before_two; end
      def before_three; end
      def before_four; end
    end
    listener = Listener1.new(builder)
    
    builder.before_one.should == []
    builder.before_two.should == [listener.method(:before_two)]
    builder.before_three.should == [three_proc, listener.method(:before_three)]
  end
  
  it "should add on_error function as builder listener" do
    class Builder2
      attr_accessor :before_one
      attr_accessor :on_error
    end
    builder = Builder2.new
    builder.before_one = []
    builder.on_error = []
    
    class Listener2 < Ruby2Jar::Listener
      def before_one; end
      def on_error; end
    end
    listener = Listener2.new(builder)
    
    builder.before_one.should == [listener.method(:before_one)]
    builder.on_error.should == [listener.method(:on_error)]
  end
  
end