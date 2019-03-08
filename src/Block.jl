struct Block
    version::Integer
    prev_block::Array{UInt8,1}
    merkle_root::Array{UInt8,1}
    timestamp::Integer
    bits::Array{UInt8,1}
    nonce::Array{UInt8,1}
    Block(version, prev_block, merkle_root, timestamp, bits, nonce) = new(version, prev_block, merkle_root, timestamp, bits, nonce)
end

function show(io::IO, z::Block)
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
function blockparse(s::IOBuffer)
    version = bytes2int(read(s, 4), true)
    prev_block = reverse!(read(s, 32))
    merkle_root = reverse!(read(s, 32))
    timestamp = bytes2int(read(s, 4), true)
    bits = read(s, 4)
    nonce = read(s, 4)
    return Block(version, prev_block, merkle_root, timestamp, bits, nonce)
end
