=begin
Rake task for building.

Copyright (C) 2008 Andrey "A.I." Sitnik <andrey@sitnik.ru>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

module Ruby2Jar
  # Rake task to build JAR.
  #
  # Example:
  # 
  #   require "rubygems"
  #   require "ruby2jar"
  #   
  #   PKG_NAME = "program"
  #   PKG_VERSION = "0.1"
  #   
  #   Ruby2Jar::Rake::JarTask.new do |jar|
  #     jar.files = FileList["lib/**/*", "bin/*"]
  #     jar.main = "bin/program"
  #     jar.name = PKG_NAME
  #     jar.version = PKG_VERSION
  #     jar.add_dependency "rspec"
  #   end
  class JarTask
    # Name of JAR package
    attr_accessor :name

    # Version of application to use in JAR name
    attr_accessor :version

    # Create an RDoc task named +task+ (default task name is +jar+)
    def initialize(task = :jar)
      @task = task
      @builder = Builder.new
      Console.new(@builder)
      yield self if block_given?
      if @builder.jar.nil? and not @name.nil?
        if not @version.nil?
          @builder.jar = "pkg/#{@name}-#{@version}.jar"
        else
          @builder.jar = "pkg/#{@name}.jar"
        end
      end
      define
    end

    # Create the tasks
    def define
      task :package => [@task]
      desc "Build the JAR file #{@builder.jar}"
      task @task do
        @builder.build
      end

      task :clobber => ["clobber_#{@task}"]
      desc "Remove JAR file #{@builder.jar}"
      task "clobber_#{@task}" do
        File.delete @builder.jar if File.exists? @builder.jar
        pkg = File.dirname(@builder.jar)
        Dir.delete pkg if Dir.entries(pkg)
      end
    end

    # Set parameters of JAR builder
    def method_missing(method, *args)
      if not @builder.method(method).nil?
        @builder.method(method).call(*args)
      else
        super(method, *args)
      end
    end
  end
end