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
 function read_varint(s::Base.GenericIOBuffer{Array{UInt8,1}})
     i = UInt8[]
     readbytes!(s, i, 1)
     if i == [0xfd]
         # 0xfd means the next two bytes are the number
         readbytes!(s, i, 2)
         return reinterpret(Int16, i)[1]
     elseif i == [0xfe]
         # 0xfe means the next four bytes are the number
         readbytes!(s, i, 4)
         return reinterpret(Int32, i)[1]
     elseif i == [0xff]
         # 0xff means the next eight bytes are the number
         readbytes!(s, i, 8)
         return reinterpret(Int64, i)[1]
     else
         # anything else is just the integer
         return reinterpret(Int8, i)[1]
     end
 end

"""
Encodes an integer as a varint
"""
 function encode_varint(n::Integer)
    if n < 0xfd
        return [UInt8(n)]
    elseif n < 0x10000
        return prepend!(int2bytes(n, 2, true), [0xfd])
    elseif n < 0x100000000
        return prepend!(int2bytes(n, 4, true), [0xfe])
    elseif n < 0x10000000000000000
        return prepend!(int2bytes(n, 8, true), [0xff])
    else
        error("Integer, ", n, " is too large")
    end
 end

import ECC.int2bytes

 """
Convert Integer to Array{UInt8}

int2bytes(x::Integer) -> Array{UInt8,1}
"""
function int2bytes(x::Integer, l::Integer=0, little_endian::Bool=false)
    result = reinterpret(UInt8, [hton(x)])
    i = findfirst(x -> x != 0x00, result)
    if l != 0
        i = length(result) - l + 1
    end
    result = result[i:end]
    if little_endian
        reverse!(result)
    end
    return result
end

function int2bytes(x::BigInt)
    n_bytes_with_zeros = x.size * sizeof(Sys.WORD_SIZE)
    uint8_ptr = convert(Ptr{UInt8}, x.d)
    n_bytes_without_zeros = 1

    if ENDIAN_BOM == 0x04030201
        # the minimum should be 1, else the result array will be of
        # length 0
        for i in n_bytes_with_zeros:-1:1
            if unsafe_load(uint8_ptr, i) != 0x00
                n_bytes_without_zeros = i
                break
            end
        end

        result = Array{UInt8}(undef, n_bytes_without_zeros)

        for i in 1:n_bytes_without_zeros
            @inbounds result[n_bytes_without_zeros + 1 - i] = unsafe_load(uint8_ptr, i)
        end
    else
        for i in 1:n_bytes_with_zeros
            if unsafe_load(uint8_ptr, i) != 0x00
                n_bytes_without_zeros = i
                break
            end
        end

        result = Array{UInt8}(undef, n_bytes_without_zeros)

        for i in 1:n_bytes_without_zeros
            @inbounds result[i] = unsafe_load(uint8_ptr, i)
        end
    end
    return result
end

import ECC.bytes2int

"""
Convert UInt8 Array to Integers

bytes2big(x::Array{UInt8,1}) -> BigInt
"""
function bytes2int(x::Array{UInt8,1}, little_endian::Bool=false)
    if length(x) > 8
        bytes2big(x)
    else
        missing_zeros = div(Sys.WORD_SIZE, 8) -  length(x)
        if missing_zeros > 0
            if little_endian
                for i in 1:missing_zeros
                    push!(x,0x00)
                end
            else
                for i in 1:missing_zeros
                    pushfirst!(x,0x00)
                end
            end
        end
        if ENDIAN_BOM == 0x04030201 && little_endian
        elseif ENDIAN_BOM == 0x04030201 || little_endian
            reverse!(x)
        end
        return reinterpret(Int, x)[1]
    end
end

function bytes2big(x::Array{UInt8,1})
    hex = bytes2hex(x)
    return parse(BigInt, hex, base=16)
end

"""
Double sha256 function
"""
function hash256(x::Array{UInt8, 1})
    return sha256(sha256(x))
end
