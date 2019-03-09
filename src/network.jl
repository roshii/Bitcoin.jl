const TX_DATA_TYPE = 1
const BLOCK_DATA_TYPE = 2
const FILTERED_BLOCK_DATA_TYPE = 3
const COMPACT_BLOCK_DATA_TYPE = 4

"""
NETWORK_MAGIC is testnet if `true`
"""
const NETWORK_MAGIC = Dict([
    (false, [0xf9, 0xbe, 0xb4, 0xd9])
    (true, [0x0b, 0x11, 0x09, 0x07])
])


struct NetworkEnvelope
    command
    payload
    magic
    NetworkEnvelope(command, payload, testnet=false) = new(command, payload, NETWORK_MAGIC[testnet])
end

function show(io::IO, z::NetworkEnvelope)
    print(io, String(z.command),
          "\n", bytes2hex(z.payload))
end

"""
Takes a stream and creates a NetworkEnvelope
"""
function io2envelope(s::IOBuffer, testnet::Bool=false)
    magic = read(s, 4)
    if magic == UInt8[]
        error("Connection reset!")
    end
    if magic != NETWORK_MAGIC[testnet]
        error("magic is not right ", bytes2hex(magic), " vs ", bytes2hex(NETWORK_MAGIC[testnet]))
    end
    command = read(s, 12)
    first = findfirst(isequal(0x00), command)
    command = command[1:first-1]
    payload_length = bytes2int(read(s, 4))
    checksum = read(s, 4)
    payload = read(s, payload_length)
    calculated_checksum = hash256(payload)[1:4]
    if calculated_checksum != checksum
        error("checksum does not match ", calculated_checksum, " vs ", checksum)
    end
    return NetworkEnvelope(command, payload, testnet)
end

"""
Returns the byte serialization of the entire network message
"""
function serialize(envelope::NetworkEnvelope)
    result = copy(envelope.magic)
    append!(result, envelope.command)
    append!(result, fill(0x00, (12 - length(envelope.command))))
    append!(result, int2bytes(length(envelope.payload), 4, true))
    append!(result, hash256(envelope.payload)[1:4])
    append!(result, envelope.payload)
    return result
end

"""
Returns a stream for parsing the payload
"""
function stream(envelope::NetworkEnvelope)
    return IOBuffer(envelope.payload)
end
