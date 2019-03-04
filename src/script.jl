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

"""
Takes a hash160 and returns the p2pkh scriptPubKey
"""
function p2pkh_script(h160::Array{UInt8,1})
    script = Union{UInt8, Array{UInt8,1}}[]
    pushfirst!(script, 0x76, 0xa9)
    push!(script, h160, 0x88, 0xac)
    return Script(script)
end


"""
Takes a hash160 and returns the p2sh scriptPubKey
"""
function p2sh_script(h160::Array{UInt8,1})
    script = Union{UInt8, Array{UInt8,1}}[]
    pushfirst!(script, 0xa9)
    push!(script, h160, 0x87)
    return Script(script)
end

function scripttype(script::Script)
    if is_p2pkh(script)
        return "P2PKH"
    elseif is_p2sh(script)
        return "P2SH"
    else
        return error("Unknown Script type")
    end
end

"""
Returns whether this follows the
OP_DUP OP_HASH160 <20 byte hash> OP_EQUALVERIFY OP_CHECKSIG pattern.
"""
function is_p2pkh(script::Script)
    return length(script.instructions) == 5 &&
        script.instructions[1] == 0x76 &&
        script.instructions[2] == 0xa9 &&
        typeof(script.instructions[3]) == Array{UInt8,1} &&
        length(script.instructions[3]) == 20 &&
        script.instructions[4] == 0x88 &&
        script.instructions[5] == 0xac
end

"""
Returns whether this follows the
OP_HASH160 <20 byte hash> OP_EQUAL pattern.
"""
function is_p2sh(script::Script)
    return length(script.instructions) == 3 &&
           script.instructions[1] == 0xa9 &&
           typeof(script.instructions[2]) == Array{UInt8,1} &&
           length(script.instructions[2]) == 20 &&
           script.instructions[3] == 0x87
end

const H160_INDEX = Dict([
    ("P2PKH", 3),
    ("P2SH", 2)
])

"""
Returns the address corresponding to the script
"""
function script2address(script::Script, testnet::Bool)
    type = scripttype(script)
    h160 = script.instructions[H160_INDEX[type]]
    return h160_2_address(h160, testnet, type)
end
