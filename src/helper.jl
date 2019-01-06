"""
    Copyright (C) 2018-2019 Simon Castano

    This file is part of Bitcoin.jl

    Bitcoin.jl is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    Bitcoin.jl is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
"""

"""
read_varint reads a variable integer from a stream
"""
 function read_varint(s::Base.CodeUnits)
     i = s.read(1)[0]
     if i == 0xfd
         # 0xfd means the next two bytes are the number
         return reinterpret(UInt16, s.read(2))
     elseif i == 0xfe
         # 0xfe means the next four bytes are the number
         return reinterpret(UInt32, s.read(4))
     elseif i == 0xff
         # 0xff means the next eight bytes are the number
         return reinterpret(UInt64, s.read(8))
     else
         # anything else is just the integer
         return i
     end
 end
