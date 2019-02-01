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

mutable struct Script
    instructions::Array{Union{UInt8, Array{UInt8, 1}}, 1}
    Script(instructions::Nothing) = new(Union{UInt8, Array{UInt8, 1}}[])
    Script(instructions) = new(instructions)
end

function show(io::IO, z::Script)
    for instruction in z.instructions
        if typeof(instruction) <: Integer
            if haskey(OP_CODE_NAMES, instruction)
                print(io, "\n", OP_CODE_NAMES[Int(instruction)])
            else
                print(io, "\n", string("OP_CODE_", Int(instruction)))
            end
        else
            print(io, "\n", bytes2hex(instruction))
        end
    end
end

"""
    scriptparse(::GenericIOBuffer) -> Script

Returns a Script object from an IOBuffer
"""
function scriptparse(s::Base.GenericIOBuffer{Array{UInt8,1}})
    length_ = read_varint(s)
    instructions = []
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
            count += n[1] + 1
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
    result = UInt8[]
    for instruction in s.instructions
        if typeof(instruction) == UInt8
            append!(result, instruction)
        else
            length_ = length(instruction)
            if length_ < 0x4b
                append!(result, UInt8(length_))
            elseif length_ > 0x4b && length_ < 0x100
                append!(result, 0x4c)
                append!(result, UInt8(length_))
            elseif length_ >= 0x100 && length_ <= 0x208
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
    result = rawserialize(s)
    total = length(result)
    prepend!(result, encode_varint(total))
    return result
end

"""
    scriptevaluate(s::Script, z::Integer) -> Bool

Evaluate if Script is valid given the transaction signature hash
"""
function scriptevaluate(s::Script, z::Integer)
    instructions = copy(s.instructions)
    stack = Array{UInt8,1}[]
    altstack = Array{UInt8,1}[]
    while length(instructions) > 0
        instruction = popfirst!(instructions)
        if typeof(instruction) <: Integer
            operation = OP_CODE_FUNCTIONS[instruction]
            function badop(instruction::Integer)
                println("bad op: ", OP_CODE_NAMES[instruction])
            end
            if instruction in (99, 100)
                # op_if/op_notif require the  array
                if !operation(stack, instructions)
                    badop(instruction)
                    return false
                end
            elseif instruction in (107, 108)
                # op_toaltstack/op_fromaltstack require the altstack
                if !operation(stack, altstack)
                    badop(instruction)
                    return false
                end
            elseif instruction in (172, 173, 174, 175)
                if !operation(stack, z)
                    badop(instruction)
                    return false
                end
            elseif !operation(stack)
                badop(instruction)
                return false
            end
        else
            push!(stack, instruction)
        end
    end
    if length(stack) == 0
        return false
    end
    if pop!(stack) == Array{UInt8,1}[]
        return false
    end
    return true
end
