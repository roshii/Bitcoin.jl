"""
    This file is part of bitcoin.jl

    bitcoin.jl is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    bitcoin.jl is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with bitcoin.jl.  If not, see <https://www.gnu.org/licenses/>.
"""

BASE58_ALPHABET = b"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

function encodebase58(s::Array{UInt8,1})
    prefix = []
    for c in s
        if c == 0
            push!(prefix, 0x31)
        else
            break
        end
    end
    num = parse(BigInt, bytes2hex(s), base=16)
    result = []
    while num > 0
        num, i = divrem(num, 58)
        pushfirst!(result, BASE58_ALPHABET[i+1])
    end
    return AbstractArray{UInt8,1}(cat(prefix, result; dims=1))
end

function bytestobase58(a::AbstractArray{UInt8})
    result = ""
    i = 1
    while i <= length(a)
        result = string(result,Char(a[i]))
        i += 1
    end
    return result
end

# Takes bytes and turns it into base58 encoding with checksum
function encodebase58checksum(h160::Array{UInt8,1})
    checksum = sha256(sha256(h160))[1:4]
    base58bytes = encodebase58(cat(h160, checksum; dims=1))
    return bytestobase58(base58bytes)
end
