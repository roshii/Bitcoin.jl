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
    command::Array{UInt8,1}
    payload::Array{UInt8,1}
    magic::Array{UInt8,1}
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

abstract type AbstractMessage end

const DEFAULT = Dict([
    ("version", 70015),
    ("services", 0),
    ("receiver_services", 0),
    ("receiver_ip", fill(0x00, 4)),
    ("receiver_port", 8333),
    ("sender_services", 0),
    ("sender_ip", fill(0x00, 4)),
    ("sender_port", 8333),
    ("latest_block", 0),
    ("relay", true)
])

struct VersionMessage <: AbstractMessage
    version::Integer
    services::Integer
    timestamp::Integer
    receiver_services::Integer
    receiver_ip::Array{UInt8,1}
    receiver_port::Integer
    sender_services::Integer
    sender_ip::Array{UInt8,1}
    sender_port::Integer
    nonce::Array{UInt8,1}
    user_agent::Array{UInt8,1}
    latest_block::Integer
    relay::Bool
    VersionMessage(timestamp::Integer, nonce::Array{UInt8,1}) = new(
        DEFAULT["version"],
        DEFAULT["services"],
        timestamp,
        DEFAULT["receiver_services"],
        DEFAULT["receiver_ip"], DEFAULT["receiver_port"],
        DEFAULT["sender_services"],
        DEFAULT["sender_ip"], DEFAULT["sender_port"],
        nonce,
        USER_AGENT,
        DEFAULT["latest_block"],
        DEFAULT["relay"])
end

"""
Serialize this message to send over the network
    version is 4 bytes little endian
    services is 8 bytes little endian
    timestamp is 8 bytes little endian
    receiver services is 8 bytes little endian
    IPV4 is 10 00 bytes and 2 ff bytes then receiver ip
    receiver port is 2 bytes, little endian
    sender services is 8 bytes little endian
    IPV4 is 10 00 bytes and 2 ff bytes then sender ip
    sender port is 2 bytes, little endian
    latest block is 4 bytes little endian
    relay is 00 if false, 01 if true
"""
function serialize(version::VersionMessage)
    result = int2bytes(version.version, 4, true)
    append!(result, int2bytes(version.services, 8, true))
    append!(result, int2bytes(version.timestamp, 8, true))
    append!(result, int2bytes(version.receiver_services, 8, true))
    append!(result, fill(0x00, 10))
    append!(result, [0xff, 0xff])
    append!(result, version.receiver_ip)
    append!(result, int2bytes(version.receiver_port, 2, true))
    append!(result, int2bytes(version.sender_services, 8, true))
    append!(result, fill(0x00, 10))
    append!(result, [0xff, 0xff])
    append!(result, version.sender_ip)
    append!(result, int2bytes(version.sender_port, 2, true))
    append!(result, version.nonce)
    append!(result, encode_varint(length(version.user_agent)))
    append!(result, version.user_agent)
    append!(result, int2bytes(version.latest_block, 4, true))
    version.relay ? append!(result, [0x01]) : append!(result, [0x00])
    return result
end

struct VerAckMessage <: AbstractMessage
    VerAckMessage() = new()
end

payload2verack(io::IOBuffer) = VerAckMessage()

serialize(::VerAckMessage) = UInt8[]

struct PingMessage <: AbstractMessage
    nonce::Array{UInt8,1}
    PingMessage(nonce) = new(nonce)
end

payload2ping(io::IOBuffer) = PingMessage(read(io, 8))

serialize(ping::PingMessage) = ping.nonce

struct PongMessage <: AbstractMessage
    nonce::Array{UInt8,1}
    PongMessage(nonce) = new(nonce)
end

payload2pong(io::IOBuffer) = PongMessage(read(io, 8))

serialize(pong::PongMessage) = pong.nonce

struct GetHeadersMessage <: AbstractMessage
    version::Integer
    num_hashes::Integer
    start_block::Array{UInt8,1}
    end_block::Array{UInt8,1}
    GetHeadersMessage(version::Integer, num_hashes::Integer, start_block::Array{UInt8,1}, end_block::Array{UInt8,1}=fill(0x00, 32)) = new(version, num_hashes, start_block, end_block)
end

GetHeadersMessage(start_block::Array{UInt8,1}) = GetHeadersMessage(DEFAULT["version"], 1, start_block)

"""
Serialize this message to send over the network
    protocol version is 4 bytes little-endian
    number of hashes is a varint
    start block is in little-endian
    end block is also in little-endian
"""
function serialize(getheaders::GetHeadersMessage)
    result = int2bytes(getheaders.version, 4, true)
    append!(result, encode_varint(getheaders.num_hashes))
    append!(result, reverse!(copy(getheaders.start_block)))
    append!(result, reverse!(copy(getheaders.end_block)))
    return result
end

struct HeadersMessage <: AbstractMessage
    headers::Array{BlockHeader,1}
    HeadersMessage(headers::Array{BlockHeader,1}) = new(headers)
end

"""
    # number of headers is in a varint
    # initialize the headers array
    # loop through number of headers times
    # add a header to the headers array by parsing the stream
    # read the next varint (num_txs)
    # num_txs should be 0 or raise a RuntimeError
"""
function payload2headers(io::IOBuffer)
    num_headers = read_varint(io)
    headers = BlockHeader[]
    for i in 1:num_headers
        push!(headers, io2blockheader(io))
        num_txs = read_varint(io)
        if num_txs != 0
            error("number of txs not 0")
        end
    end
    return HeadersMessage(headers)
end

const PARSE_PAYLOAD = Dict([
    (b"verack", payload2verack),
    (b"ping", payload2ping),
    (b"pong", payload2pong),
    (b"headers", payload2headers)
])
