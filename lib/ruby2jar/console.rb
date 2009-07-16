=begin
Command line interface for ruby2jar builder.

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
  # Command line interface for builder. Check builder parameters and
  # print error and warnings to console.
  class Console < Listener
    # Print message for standart builder error
    def on_error(error)
      if Error == error.class
        STDERR.puts "ERROR: #{error.message}"
        true
      else
        false
      end
    end
  end
end