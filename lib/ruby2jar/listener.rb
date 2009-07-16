=begin
Simple metaclass to create extensions for builder.

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
  # Simple metaclass to create extensions for builder, which provide user
  # interface or special functions, such as creating Java Web Start files.
  #
  # It add all listener methods started by "before_" to builder.
  class Listener
    # Add listeners to +builder+
    def initialize(builder = nil)
      if not builder.nil?
        @builder = builder
        builder.methods.reject {|i| not i =~ /^(before_|on_error$)/}.each do |m|
          if methods.include? m
            builder.method(m).call << method(m)
          end
        end
      end
    end
  end
end
