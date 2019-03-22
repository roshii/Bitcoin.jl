abstract type AbstractMessage end

struct NetworkEnvelope
    magic::UInt32
    command::String
    length::UInt32
    checksum::UInt32
    payload::Array{UInt8,1}
    NetworkEnvelope(magic::UInt32, command::AbstractString, length::Integer, checksum::UInt32, payload::Array{UInt8,1}) = new(magic, command, length, checksum, payload)
end

NetworkEnvelope(command::AbstractString, payload::Array{UInt8,1}, testnet=false) = NetworkEnvelope(NETWORK_MAGIC[testnet], command, length(payload), reinterpret(UInt32, hash256(payload))[1], payload)
NetworkEnvelope(command::AbstractString, payload::AbstractMessage, testnet=false) = NetworkEnvelope(command, serialize(payload), testnet)

function show(io::IO, z::NetworkEnvelope)
    print(io, "Network Envelope - ", z.command, "\n", z.length, " bytes, checksum ", string(z.checksum, base=16), " on network ", string(z.magic, base=16), "\n--------\n", bytes2hex(z.payload))
end

"""
    IOBuffer, Bool -> Array{NetworkEnvelope,1}

Takes a stream and creates a NetworkEnvelope
"""
function io2envelope(bin::Array{UInt8,1}, testnet::Bool=false)
    s = IOBuffer(bin)
    result = NetworkEnvelope[]
    while bytesavailable(s) > 0
        try
            global magic = reinterpret(UInt32, read(s, 4))[1]
        catch BoundsError
            error("Connection reset!", bytes2hex(bin))
        end
        if magic != NETWORK_MAGIC[testnet]
            error("magic is not right ", magic, " vs ", NETWORK_MAGIC[testnet])
        end
        command = strip(String(read(s, 12)), '\0')
        payload_length = reinterpret(UInt32, read(s, 4))[1]
        checksum = reinterpret(UInt32, read(s, 4))[1]
        payload = read(s, payload_length)
        calculated_checksum = reinterpret(UInt32, hash256(payload)[1:4])[1]
        if calculated_checksum != checksum
            error("Error parsing IO, calculated checksum does not match ", calculated_checksum, " vs ", checksum)
        end
        push!(result, NetworkEnvelope(magic, command, payload_length, checksum, payload))
    end
    result
end

"""
Returns the byte serialization of the entire network message
"""
function serialize(envelope::NetworkEnvelope)
    result = Array(reinterpret(UInt8, [htol(envelope.magic)]))
    append!(result, UInt8.(collect(envelope.command)))
    append!(result, fill(0x00, (12 - length(envelope.command))))
    append!(result, int2bytes(length(envelope.payload), 4, true))
    append!(result, int2bytes(envelope.checksum, 4, true))
    append!(result, envelope.payload)
end

struct Peer
    time::UInt32
    services::UInt64
    ip::IPAddr
    port::UInt16
    Peer(services::Integer, ip::IPAddr, port::Integer, time::Integer=0) = new(time, services, ip, port)
end

Peer(testnet::Bool=false) = Peer(DEFAULT["services"], DEFAULT["ip"], DEFAULT["port"][testnet])
Peer(ip::IPAddr, port::Integer) = Peer(DEFAULT["services"], ip, port)

function show(io::IO, z::Peer)
    print(io, z.services, "@", z.ip, ":", z.port)
end

"""
    IPv4 -> Array{UInt8,1}

Return an 16 bytes UInt8 array representing the IP address

IPv6 address. Network byte order. The original client only supported IPv4 and
only read the last 4 bytes to get the IPv4 address. However, the IPv4 address
is written into the message as a 16 byte IPv4-mapped IPv6 address

(12 bytes 00 00 00 00 00 00 00 00 00 00 FF FF, followed by the 4 bytes of the
IPv4 address).
"""
function ip2bytes(ip::IPv4)
    result = fill(0x00, 10)
    append!(result, [0xff, 0xff])
    append!(result, Array(reinterpret(UInt8, [hton(ip.host)])))
end

"""
    Peer -> Array{UInt8,1}

Returns the serialization of a Peer
"""
function serialize(peer::Peer, versionmessage::Bool=false)
    result = UInt8[]
    if !versionmessage
        append!(result, Array(reinterpret(UInt8, [htol(peer.time)])))
    end
    append!(result, Array(reinterpret(UInt8, [htol(peer.services)])))
    append!(result, ip2bytes(peer.ip))
    append!(result, Array(reinterpret(UInt8, [hton(peer.port)])))
end

"""
    parse_peer(payload::Array{UInt8,1}) -> Peer

Parse Peer from bytes arrays
"""
function parse_peer(payload::Array{UInt8,1}, versionmessage::Bool=false)
    io = IOBuffer(payload)
    if versionmessage
        time = ltoh(reinterpret(UInt32, read(io, 4))[1])
    else
        time = 0
    end
    services = ltoh(reinterpret(UInt64, read(io, 8))[1])
    ip_bytes = read(io, 16)
    if ip_bytes[1:12] == IPV4_PREFIX
        ip = IPv4(ntoh(reinterpret(UInt32, ip_bytes[13:16])[1]))
    else
        ip = IPv4(ntoh(reinterpret(UInt128, ip_bytes)[1]))
    end
    port = ntoh(reinterpret(UInt16, read(io, 8))[1])
    Peer(services, ip, port, time)
end

struct VersionMessage <: AbstractMessage
    command::String
    version::UInt32
    services::UInt64
    timestamp::UInt64
    receiver::Peer
    sender::Peer
    nonce::UInt64
    user_agent::String
    start_height::UInt32
    relay::Bool
    VersionMessage(version::Integer, services::Integer, timestamp::Integer, receiver::Peer, sender::Peer, nonce::Integer, user_agent::String, start_height::Integer, relay::Bool) = new("version", version, services, timestamp, receiver, sender, nonce, user_agent, start_height, relay)
end

VersionMessage(timestamp::UInt64, nonce::UInt64, testnet::Bool=false) =
    VersionMessage(DEFAULT["version"],
                   DEFAULT["services"],
                   timestamp,
                   Peer(testnet), Peer(testnet),
                   nonce,
                   USER_AGENT,
                   DEFAULT["start_height"],
                   DEFAULT["relay"])
VersionMessage(testnet::Bool=false) =
    VersionMessage(UInt64(round(time())), rand(UInt64), testnet)

function show(io::IO, z::VersionMessage)
    print(io, "Version Message\n--------\nVersion : ",
            z.version, " - User Agent : ", String(z.user_agent),
            "\nServices : ", z.services, " - Relay : ", z.relay,
            "\nTime Stamp : ", unix2datetime(z.timestamp),
            "\nLatest Block : ", string(z.start_height, base=16),
            "\nReceiver : ", z.receiver,
            "\nSender : ", z.sender)
end

"""
    serialize(version::VersionMessage) -> Array{UInt8,1}

Serialize this message to send over the network
"""
function serialize(version::VersionMessage)
    result = Array(reinterpret(UInt8, [htol(version.version)]))
    append!(result, Array(reinterpret(UInt8, [htol(version.services)])))
    append!(result, Array(reinterpret(UInt8, [htol(version.timestamp)])))
    append!(result, serialize(version.receiver, true))
    append!(result, serialize(version.sender, true))
    append!(result, Array(reinterpret(UInt8, [htol(version.nonce)])))
    append!(result, serialize(VarString(version.user_agent)))
    append!(result, Array(reinterpret(UInt8, [htol(version.start_height)])))
    version.relay ? append!(result, [0x01]) : append!(result, [0x00])
    return result
end

"""
    serialize(version::VersionMessage) -> Array{UInt8,1}

"""
function payload2version(payload::Array{UInt8,1})
    io = IOBuffer(payload)
    version = ltoh(reinterpret(UInt32, read(io, 4))[1])
    services = ltoh(reinterpret(UInt64, read(io, 8))[1])
    timestamp = ltoh(reinterpret(UInt64, read(io, 8))[1])
    sender = parse_peer(read(io, 26))
    receiver = parse_peer(read(io, 26))
    nonce = ltoh(reinterpret(UInt64, read(io, 8))[1])
    user_agent = io2varstring(io).str
    start_height = ltoh(reinterpret(UInt32, read(io, 4))[1])
    relay = Bool(read(io, 1)[1])
    VersionMessage(version, services, timestamp, receiver, sender, nonce, user_agent, start_height, relay)
end

struct VerAckMessage <: AbstractMessage
    command::String
    VerAckMessage() = new("verack")
end

payload2verack(payload::Array{UInt8,1}) = VerAckMessage()

serialize(::VerAckMessage) = UInt8[]

struct PingMessage <: AbstractMessage
    command::String
    nonce::Array{UInt8,1}
    PingMessage(nonce) = new("ping", nonce)
end

payload2ping(payload::Array{UInt8,1}) = PingMessage(payload)

serialize(ping::PingMessage) = ping.nonce

struct PongMessage <: AbstractMessage
    command::String
    nonce::Array{UInt8,1}
    PongMessage(nonce) = new("pong", nonce)
end

payload2pong(payload::Array{UInt8,1}) = PongMessage(payload)

serialize(pong::PongMessage) = pong.nonce

struct GetHeadersMessage <: AbstractMessage
    command::String
    version::UInt32
    num_hashes::Integer
    start_block::Array{UInt8,1}
    end_block::Array{UInt8,1}
    GetHeadersMessage(version::Integer, num_hashes::Integer, start_block::Array{UInt8,1}, end_block::Array{UInt8,1}=fill(0x00, 32)) = new("getheaders", version, num_hashes, start_block, end_block)
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
    command::String
    headers::Array{BlockHeader,1}
    HeadersMessage(headers::Array{BlockHeader,1}) = new("headers", headers)
end

"""
    # number of headers is in a varint
    # initialize the headers array
    # loop through number of headers times
    # add a header to the headers array by parsing the stream
    # read the next varint (num_txs)
    # num_txs should be 0 or raise a RuntimeError
"""
function payload2headers(payload::Array{UInt8,1})
    io = IOBuffer(payload)
    payload2headers(io)
end

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


mutable struct GetDataMessage <: AbstractMessage
    command::String
    data::Array{Tuple{Integer,Array{UInt8,1}},1}
    GetDataMessage(data::Array{Tuple{Integer,Array{UInt8,1}},1}=Tuple{Integer,Array{UInt8,1}}[]) = new("getdata", data)
end

import Base.append!

function append!(x::GetDataMessage, type::Integer, identifier::Array{UInt8,1})
    push!(x.data, (type, identifier))
end

function serialize(x::GetDataMessage)
    result = encode_varint(length(x.data))
    for e in x.data
        append!(result, int2bytes(e[1], 4, true))
        append!(result, reverse!(copy(e[2])))
    end
    return result
end

mutable struct RejectMessage <: AbstractMessage
    command::String
    message::String
    ccode::Char
    reason::String
    data::Array{UInt8,1}
    RejectMessage(message::String, ccode::Char, reason::String, data::Array{UInt8,1}) = new("reject", message, ccode, reason, data)
end

function show(io::IO, z::RejectMessage)
    print(io, "Reject Message\n--------\nMessage : ",
            z.message, "\nccode : ", z.ccode,
            "\nReason : ", z.reason, "\n", bytes2hex(z.data))
end

"""
    payload2reject(payload::Array{UInt8,1}) -> RejectMessage

Parse RejectMessage from NetworkEnvelope payload
"""
function payload2reject(payload::Array{UInt8,1})
    io = IOBuffer(payload)
    message = io2varstring(io).str
    ccode = Char(read(io, 1)[1])
    reason = io2varstring(io).str
    data = read(io)
    RejectMessage(message, ccode, reason, data)
end

mutable struct MerkleBlockMessage <: AbstractMessage
    command::String
    header::BlockHeader
    tx_count::UInt32
    hash_count::Unsigned
    hashes::Array{Array{UInt8,1},1}
    flag_byte_count::Unsigned
    flags::Array{Bool,1}
    MerkleBlockMessage(header::BlockHeader, tx_count::Integer,
                  hash_count, hashes::Array{Array{UInt8,1},1}, flag_byte_count,
                  flags::Array{Bool,1}) = new("merkleblock",
                  header, tx_count, hash_count, hashes, flag_byte_count, flags)
end

function show(io::IO, z::MerkleBlockMessage)
    print(io, "Merkle Block Message\n--------\nMessage : ",
            z.header, "\ntx_count : ", z.tx_count,
            " flag_byte_count : ", z.flag_byte_count)
end

"""
    bytes2flags(bytes::Array{UInt8,1}) -> Array{Bool,1}

Returns an Array{Bool,1} representing bits
"""
function bytes2flags(bytes::Array{UInt8,1})
    result = Bool[]
    for byte in bytes
        for i in 0:7
            push!(result, (byte & (0x01 << i)) != 0)
        end
    end
    result
end

"""
    payload2merkleblock(payload::Array{UInt8,1}) -> MerkleBlockMessage

Parse MerkleBlockMessage from NetworkEnvelope payload
"""
function payload2merkleblock(payload::Array{UInt8,1})
    io = IOBuffer(payload)
    header = io2blockheader(io)
    tx_count = ltoh(reinterpret(UInt32, read(io, 4))[1])
    hash_count = read_varint(io)
    hashes = Array{UInt8,1}[]
    for i in 1:hash_count
         push!(hashes, read(io, 32))
    end
    flag_byte_count = read_varint(io)
    flag_byte = read(io, flag_byte_count)
    flags = bytes2flags(flag_byte)
    MerkleBlockMessage(header, tx_count, hash_count, hashes, flag_byte_count, flags)
end

"""

Returns true if MerkleBlockMessage is valid
"""
function is_valid(mb::MerkleBlockMessage)
    tree = MerkleTree(mb.tx_count)
    populate!(tree, mb.flags, mb.hashes)
    root(tree) == mb.header.merkle_root
end

PARSE_PAYLOAD = Dict([
    ("version", payload2version),
    ("verack", payload2verack),
    ("ping", payload2ping),
    ("pong", payload2pong),
    ("headers", payload2headers),
    ("merkleblock", payload2merkleblock),
    ("reject", payload2reject)

])
