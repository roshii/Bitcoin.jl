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

struct Script
    instructions::Array{Union{UInt8, Array{UInt8, 1}}, 1}
    Script(instructions=nothing) = new(Array{UInt8, 1}[])
    Script(instructions::Union{UInt8, Array{UInt8, 1}}) = new([instructions])
    Script(instructions) = new(instructions)
end

"""
    scriptparse(s::Script) -> Script
"""
function scriptparse(s::Script)
    s = IOBuffer(s.instructions[1])
    length_ = read_varint(s)
    instructions = Array{UInt8,1}[]
    count = 0
    while count < length_
        current = UInt8[]
        readbytes!(s, current, 1)
        count += 1
        current_byte = current[1]
        if current_byte >= 1 && current_byte <= 75
            n = current_byte
            instruction = UInt8[]
            readbytes!(s, instruction, n)
            push!(instructions, instruction)
            count += n
        elseif current_byte == 76
            # op_pushdata1
            n = UInt8[]
            readbytes!(s, n, 1)
            instruction = UInt8[]
            readbytes!(s, instruction, n[1])
            push!(instructions, instruction)
            count += n + 1
        elseif current_byte == 77
            # op_pushdata2
            n = UInt8[]
            readbytes!(s, n, 2)
            n = reinterpret(Int16, n)[1]
            instruction = UInt8[]
            readbytes!(s, instruction, n)
            push!(instructions, instruction)
            count += n + 2
        else
            # op_code
            push!(instructions, current_byte)
        end
    end
    if count != length_
        error("Error: parsing Script failed")
    end
    return Script(instructions)
end

function rawserialize(s::Script)
    # initialize what we'll send back
    result = UInt8[]
    # go through each instruction
    for instruction in s.instructions
        # if the instruction is an integer, it's an op code
        if typeof(instruction) == UInt8
            # turn the instruction into a single byte integer using int_to_little_endian
            append!(result, instruction)
        else
            # otherwise, this is an element
            # get the length in bytes
            length_ = length(instruction)
            # for large lengths, we have to use a pushdata op code
            if length_ < 0x4b
                # turn the length into a single byte integer
                append!(result, UInt8(length_))
            elseif length_ > 0x4b && length_ < 0x100
                # 76 is pushdata1
                append!(result, 0x4c)
                append!(result, UInt8(length_))
            elseif length_ >= 0x100 && length_ <= 0x208
                # 77 is pushdata2
                append!(result, 0x4d)
                result += int2bytes(length_, 2)
            else
                error("too long an instruction")
            end
            append!(result, instruction)
        end
    end
    return result
end

function scriptserialize(s::Script)
    # get the raw serialization (no prepended length)
    result = rawserialize(s)
    # get the length of the whole thing
    total = length(result)
    # encode_varint the total length of the result and prepend
    return prepend!(result, encode_varint(total))
end
