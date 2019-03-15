"""
Double sha256 function
"""
function hash256(x::Array{UInt8, 1})
    return sha256(sha256(x))
end

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

struct VarString <: AbstractString
    len::Integer
    str::String
    VarString(str::String) = new(length(str), str)
end

serialize(x::VarString) = append!(encode_varint(x.len), x.str)

io2varstring(io::IOBuffer) = VarString(String(read(io, read_varint(io))))
