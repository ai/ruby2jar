=begin
Build JAR from Ruby script.

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

require "tmpdir"
require "tempfile"
require "yaml"
require "fileutils"

require "rubygems"
require "rake"

module Ruby2Jar
  # Ruby2Jar builds JAR from a Ruby script. It copies gems, compiles sources 
  # and packages JAR. It is an easy way to distribute your JRuby application or 
  # create Applet or Java Web Start.
  # 
  # == Examples
  # === Build from Rake task (best production way)
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
  # 
  # === Build with console output
  # 
  #   require "rubygems"
  #   require "ruby2jar"
  #   
  #   builder = Ruby2Jar::Builder.new
  #   console = Ruby2Jar::Console.new(builder)    # Add console error output
  #   builder.path = "/path/to/ruby/program/"     # Set program to build
  #   builder.files = Rake::FileList["/lib/**/*"] # Select files
  #   builder.add_dependency "actionsupport"      # Add gems
  #   builder.add_dependency "rspec", ">=1.0.0"   # Add gem with special version
  #   builde.build                                # Start building
  # 
  # == Extension
  # You can add some action in building work. For example, to show warning
  # dialogs or to create special manifest file. Just add new Proc or Method
  # object to "before_*" arrays with neccessary building step.
  # 
  # You can also extend Ruby2Jar::Listener to create extension, which
  # automatically connect all function to builder. 
  # 
  # === Example
  #   
  #   require "rubygems"
  #   require "ruby2jar"
  #   
  #   builder = Ruby2Jar::Builder.new
  #   builder.path = "/path/to/ruby/program/"
  #   builder.add_dependency "rspec"
  #   
  #   builder.before_start  << lambda {        # Add function, which will be
  #     puts "Jar building is start"           # call before builder start and
  #   }                                        # set system variables
  #   
  #   builder.before_finish << lambda {        # Function, which will be call
  #     puts "Jar building is finish"          # before builder finish it work  
  #   }                                        # and delete temporal files
  # 
  class Builder
    # Script or directory to build JAR
    attr_accessor :path
    
    # List of files to be included in the JAR.
    attr_accessor :files
    
    # Path to main script, which will be run whtn you execute JAR.
    # If in +path+ you set file, main script will be equal +path+.
    attr_accessor :main
    
    # Does builder must create Manifest file in JAR with +main+ script, which
    # will be start on JAR executing (default if true).
    attr_accessor :create_manifest
    
    # Custom content of Manifest file in JAR as hash. If parameters will be not
    # set, builder add Manifest-Version and Main-Class if +main+ exist.
    attr_accessor :manifest
    
    # Path to result JAR (default is +path+/pkg/{last dirname in +path+}.jar).
    attr_accessor :jar
    
    # Does builder must copy JRuby to JAR (default if true). With JRuby 
    # resulting JAR can be started on any Java Runtime, but file will be has 
    # bigger size.
    attr_accessor :include_jruby
    
    # Path to JRuby JAR (default is $JRUBY_HOME/lib/jruby/jar). Used only 
    # if +include_jruby+ is true.
    attr_accessor :jruby
    
    # Arguments for Java compiler
    attr_accessor :javac_args
    
    # Path in script, which will be added to <tt>$LOAD_PATH</tt> in init script
    # (default is root and lib dir of application)
    attr_accessor :require_paths
    
    # Create builder instance
    def initialize
      @path = Dir.pwd
      @create_manifest = false
      @manifest = {"Manifest-Version" => "1.0"}
      @include_jruby = true
      @target = "1.6"
      @require_paths = ["lib", ""]
      @javac_args = ""
      @gems_index = Gem.source_index
      
      @before_start = []
      @before_find_gems = []
      @before_copy = []
      @before_create_init = []
      @before_compile = []
      @before_package = []
      @before_finish = []
      @on_error = []
      
      @gems = []
      @configs = {}
    end
    
    # Add a dependency gem
    def add_dependency(gem, *requirements)
      @gems << [gem, requirements]
    end
    
    # Start building JAR. You must set +path+ before call it.
    def build
      @stop = false
      %w{start copy create_init compile package}.each do |step|
        method("before_#{step}").call.each do |proc|
          proc.call
        end
        if @stop
          break
        end
        method(step).call
      end
    rescue => error
      @error_rescued = false
      on_error.each do |proc|
        @error_rescued |= proc.call error
      end
      if not @error_rescued
        raise error
      end
    ensure
      begin
        before_finish.each do |proc|
          proc.call
        end
      ensure
        finish
      end
    end
    
    attr_accessor :before_start
    attr_accessor :before_copy
    attr_accessor :before_create_init
    attr_accessor :before_compile
    attr_accessor :before_package
    attr_accessor :before_finish
    attr_accessor :on_error
    
    # Path to work dir, which be used to copy all neccessary files.
    # It will be set automatically and has public access only for extensions.
    attr_accessor :build_dir
    
    # Gems, which using in program. Use +add_dependency+ to add gem.
    attr_accessor :gems
    
    # Gem's configs with building information, which was loaded from 
    # <tt>GEM_DIR/java.yaml</tt>. It will has information after +copy+ step.
    attr_accessor :configs
    
    # Paths to add to <tt>$LOAD_PATH</tt> in init script
    attr_accessor :init_require_paths
    
    # Gem's source index. It available as variable for testing and hacking.
    attr_accessor :gems_index
    
    # Gems, which is added to JAR. Contain @gems and they dependencies.
    attr_accessor :loaded_gems
    
    # Stop JAR building and delete temporal files. Must be runned from extension
    # on error or when building is not necessary yet.
    def stop
      @stop = true
    end
    
    protected
    
    # Check for errors and create temporal directory
    def start
      raise Error, "You didn't set path to source dir or file." if @path.nil?
      raise Error, "Source path is already exist." if not File.exist? @path
      
      @path = File.expand_path(@path)
      if File.directory? @path
        Dir.chdir(@path) do
          @files = Rake::FileList["**/*"] if @files.nil?
          @files.map! { |i| File.expand_path(i) }
        end
      end
      if @jar.nil?
        if File.directory? @path
          @jar = File.join(@path, "pkg", "#{@path.split('/').last}.jar")
        else
          @jar = File.join(File.dirname(@path), 
            "#{File.basename(@path, File.extname(@path))}.jar")
        end
      end
      @jar = File.expand_path(@jar)
      
      if File.exist? @jar
        raise Error, "File #{@jar} already exist. Delete it or change jar name"
      end
      
      if not @main.nil?
        @create_manifest = true
        path = File.join(@path, @main)
        if not File.exist? path
          raise Error, "Main script isn't exist in #{path}."
        end
      end
      if @main.nil? and not File.directory? @path
        @main = File.basename(@path)
      end
      
      if @include_jruby
        if @jruby.nil?
          if ENV['JRUBY_HOME'].nil?
            raise Error,  "Can't find JRuby, please set it manually."
          else
            @jruby = File.join(ENV['JRUBY_HOME'], "lib", "jruby.jar")
          end
        end
        if not File.exist? @jruby
          raise Error,  "JRuby isn't exist in #{@jruby}."
        end
      end
      
      number = Time.now.to_i
      begin
        number += 1
        @build_dir = File.join(Dir.tmpdir, "ruby2jar#{number}")
      end while File.exist? @build_dir
      @app_dir = File.join(@build_dir, "ruby", "app")
      @gems_dir = File.join(@build_dir, "ruby", "gems")
      
      @init_require_paths = @require_paths.map { |i| "ruby/app/#{i}"}
      
      Dir.mkdir @build_dir
      File.chmod 0700, @build_dir
      Dir.mkdir File.join(@build_dir, "ruby")
      Dir.mkdir @app_dir
      Dir.mkdir @gems_dir
      
      # Change current dir
      @last_current_dir = Dir.pwd
      Dir.chdir @build_dir
    end
    
    # Copy application, gems and JRuby
    def copy
      if File.directory? @path
        @files.each do |src|
          dest = File.join(@app_dir, src[@path.length..-1])
          if File.directory? src
            FileUtils.mkdir_p(dest)
          else
            FileUtils.mkdir_p(File.dirname(dest))
            FileUtils.copy src, dest
          end
        end
      else
        FileUtils.copy @path, @app_dir
      end
      
      @loaded_gem_versions = []
      @loaded_gems = []
      @gems.each { |gem| copy_gem(gem[0], gem[1]) }
      
      ([@app_dir] + Dir.glob(File.join(@gems_dir, "*"))).each do |dir|
        ext = File.join(dir, "ext")
        Dir.glob(File.join(ext, "**", "*.{java,class}")).each do |file|
          if ".java" == File.extname(file)
            if File.exist? file[0..-6] + ".class"
              File.delete file
              next
            end
          end
          dest = File.join(@build_dir, file[ext.length..-1])
          FileUtils.makedirs File.dirname(dest)
          FileUtils.move file, dest
        end
      end
    end
    
    # Find gems and copy it and it's dependencies
    def copy_gem(gem, version = nil)
      specs = @gems_index.find_name(gem, version)
      if specs.empty?
        raise Error, "Can't find gem #{gem}"
      end
      spec = specs.first
      
      if @loaded_gem_versions.include? spec.full_name
        return
      end
      if @loaded_gems.include? gem
        raise Error, "Gem #{spec.name} is already added with different version"
      end
      
      gem_dir = File.join(@gems_dir, gem)
      FileUtils.cp_r File.join(spec.full_gem_path, "."), gem_dir
      
      config = File.join(@gems_dir, gem, "java.yaml")
      if File.exist? config
        @configs[gem] = YAML::load_file(config)
        File.delete config
        jar = @configs[gem]['jar']
        if not jar.nil? and not jar['exclude'].nil?
          jar['exclude'].map { |i| File.join(gem_dir, i) }.each do |files|
            FileUtils.rm Dir.glob(files)
          end
        end
      end
      
      @loaded_gem_versions << spec.full_name
      @loaded_gems << gem
      @init_require_paths += spec.require_paths.map{|i| "ruby/gems/#{gem}/#{i}"}
      
      spec.dependencies.each { |i| copy_gem(i) }
    end
    
    # Create init script to set rubygems variables and start main script
    def create_init
      return if @main.nil?
      
      File.open(File.join(@build_dir, "ruby", "init.rb"), "w") do |file|
        file.puts "module Kernel"
        file.puts "  def gem(name, *version); end"
        file.puts "  alias ruby2jar_original_require require"
        file.puts "  def require(file)"
        file.puts "    ruby2jar_original_require(file)"
        file.puts "  rescue LoadError => error"
        file.puts "    raise error if not error.message.include? 'no such file to load'"
        file.puts "    $LOAD_PATH.each do |path|"
        file.puts "      begin"
        file.puts "        ruby2jar_original_require(File.join(path, file))"
        file.puts "        return"
        file.puts "      rescue LoadError => error"
        file.puts "        raise error if not error.message.include? 'no such file to load'"
        file.puts "      end"
        file.puts "    end"
        file.puts "  end"
        file.puts "end"
        @init_require_paths.each do |path|
          file.puts '$LOAD_PATH << "' + path + '"'
        end
        file.puts 'require "ruby/app/' + @main.sub(/\.rb$/, '') + '"'
      end
      @manifest["Main-Class"] = "ruby.init" if not @manifest.include? "Main-Class"
    end
    
    # Compile Ruby and Java sources
    def compile
      `jrubyc -p "" ./`
      
      Dir.glob(File.join(@build_dir, "**", "*.java")).each do |file|
        `javac #{@javac_args} -sourcepath ./ "#{file}"`
      end
      
      Dir.glob(File.join(@build_dir, "**", "*.{rb,java}")).each do |file|
        File.delete file
      end
    end
    
    # Package files in one JAR
    def package
      if @include_jruby
        `jar -xf "#{@jruby}"`
      end
      
      FileUtils.makedirs File.dirname(@jar)
      
      if @create_manifest
        @manifest_file = Tempfile.new("ruby2jar_manifest")
        @manifest.each_pair do |name, value|
          @manifest_file.puts "#{name}: #{value}"
        end
        @manifest_file.close(false)
        
        `jar -cvfm "#{@jar}" "#{@manifest_file.path}" ./`
      else
        `jar -cf "#{@jar}" ./`
      end
    end
    
    # Delete all temporal files
    def finish
      if not @last_current_dir.nil?
        Dir.chdir @last_current_dir
      end
      if not @build_dir.nil?
        FileUtils.rm_r @build_dir
      end
    end
  end
end