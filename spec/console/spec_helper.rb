require File.join(File.dirname(__FILE__), "..", "spec_helper")

module Ruby2Jar
  class FakeConsole < Console
    def initialize(builder, warnings = true)
      super(builder, warnings)
      @error_messages = []
      @warning_messages = []
    end
    def error(msg)
      @error_messages << msg
    end
    def warning(msg)
      @warning_messages << msg
    end
  end
end