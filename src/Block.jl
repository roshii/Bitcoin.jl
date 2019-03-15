import Base.hash

abstract type AbstractBlock end

struct BlockHeader <: AbstractBlock
    version::Integer
    prev_block::Array{UInt8,1}
    merkle_root::Array{UInt8,1}
    timestamp::Integer
    bits::Array{UInt8,1}
    nonce::Array{UInt8,1}
    BlockHeader(version, prev_block, merkle_root, timestamp, bits, nonce) = new(version, prev_block, merkle_root, timestamp, bits, nonce)
end

function show(io::IO, z::BlockHeader)
    print(io, "Block\n--------\nVersion : ", z.version,
            "\nPrevious Block : ", bytes2hex(z.prev_block),
            "\nMerkle Root : ", bytes2hex(z.merkle_root),
            "\nTime Stamp : ", unix2datetime(z.timestamp),
            "\nBits : ", bytes2hex(z.bits),
            "\nNonce : ", bytes2hex(z.nonce))
end

"""
Takes a byte stream and parses a block. Returns a Block object
"""
function io2blockheader(s::IOBuffer)
    version = bytes2int(read(s, 4), true)
    prev_block = reverse!(read(s, 32))
    merkle_root = reverse!(read(s, 32))
    timestamp = bytes2int(read(s, 4), true)
    bits = read(s, 4)
    nonce = read(s, 4)
    return BlockHeader(version, prev_block, merkle_root, timestamp, bits, nonce)
end

"""
Returns the 80 byte block header
"""
function serialize(block::BlockHeader)
    result = int2bytes(block.version, 4, true)
    prev_block = copy(block.prev_block)
    append!(result, reverse!(prev_block))
    merkle_root = copy(block.merkle_root)
    append!(result, reverse!(merkle_root))
    append!(result, int2bytes(block.timestamp, 4, true))
    append!(result, block.bits)
    append!(result, block.nonce)
    return result
end

"""
Returns the hash256 interpreted little endian of the block
"""
function hash(block::BlockHeader)
    s = Bitcoin.serialize(block)
    h256 = hash256(s)
    return reverse!(h256)
end

"""
Human-readable hexadecimal of the block hash
"""
function id(block::BlockHeader)
    return bytes2hex(hash(block))
end

"""
Returns whether this block is signaling readiness for BIP9

    BIP9 is signalled if the top 3 bits are 001
    remember version is 32 bytes so right shift 29 (>> 29) and see if
    that is 001
"""
function bip9(block::BlockHeader)
    return block.version >> 29 == 0b001
end

"""
Returns whether this block is signaling readiness for BIP91

    BIP91 is signalled if the 5th bit from the right is 1
    shift 4 bits to the right and see if the last bit is 1
"""
function bip91(block::BlockHeader)
    return block.version >> 4 & 1 == 1
end

"""
Returns whether this block is signaling readiness for BIP141

    BIP91 is signalled if the 2nd bit from the right is 1
    shift 1 bit to the right and see if the last bit is 1
"""
function bip141(block::BlockHeader)
    return block.version >> 1 & 1 == 1
end

"""
Returns the proof-of-work target based on the bits

    last byte is exponent
    the first three bytes are the coefficient in little endian
    the formula is: coefficient * 256**(exponent-3)
"""
function target(block::BlockHeader)
    exponent = block.bits[end]
    coefficient = bytes2int(block.bits[1:3], true)
    return coefficient * big(256)^(exponent - 3)
end

"""
Returns the block difficulty based on the bits

    difficulty is (target of lowest difficulty) / (block's target)
    lowest difficulty has bits that equal 0xffff001d
"""
function difficulty(block::BlockHeader)
    lowest = 0xffff * big(256)^(0x1d - 3)
    return div(lowest, target(block))
end

"""
Returns whether this block satisfies proof of work

    get the hash256 of the serialization of this block
    interpret this hash as a little-endian number
    return whether this integer is less than the target
"""
function check_pow(block::BlockHeader)
    block_hash = hash(block)
    proof = bytes2int(block_hash, true)
    return proof < target(block)
end

struct Block <: AbstractBlock
    header::BlockHeader
    tx_hashes
    merkle_tree
end
