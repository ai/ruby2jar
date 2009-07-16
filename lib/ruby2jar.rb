=begin
Load all neccessary classes.

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

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) unless
  $LOAD_PATH.include?(File.dirname(__FILE__)) ||
  $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__)))

require "ruby2jar/builder"

module Ruby2Jar
  autoload :Listener, "ruby2jar/listener"
  autoload :Console, "ruby2jar/console"
  autoload :Error, "ruby2jar/error"
  autoload :JarTask, "ruby2jar/jartask"
end