using Sockets

mutable struct Node
    host::Union{String,IPv4}
    port::Integer
    testnet::Bool
    logging::Bool
    sock::TCPSocket
    Node(host::Union{String,IPv4}, port::Integer, testnet::Bool=false, logging::Bool=false) = new(host, port, testnet, logging)
end

Node(host::Union{String,IPv4}, testnet::Bool=false) = Node(host, DEFAULT["port"][testnet], testnet)

"""
    connect!(node::Node) -> TCPSocket

Connect to the host `node.host` on port `node.port`.
"""
function connect!(node::Node)
    try
        if !isopen(node.sock)
            node.sock = connect(node.host, node.port)
        else
            node.sock
        end
    catch
        node.sock = connect(node.host, node.port)
    end
end

"""
    close!(node::Node) -> TCPSocket

Close Node's TCPSocket
"""
function close!(node::Node)
    close(node.sock)
    node.sock
end


"""
    send2node(node::Node, message::T) -> Integers

Send a message to the connected node, returns the numbers of bytes sent
"""
function send2node(node::Node, message::T) where {T<:AbstractMessage}
    envelope = NetworkEnvelope(message.command,
                               serialize(message),
                               node.testnet)
    if node.logging
        println("sending: ", envelope)
    end
    write(node.sock, serialize(envelope))
end

"""
handshake(node::Node) -> Bool

Do a handshake with the other node, returns true if successful
Handshake is sending a version message and getting a verack back.
"""
function handshake(node::Node)
    try
        connect!(node)
        @async read(node.sock)
        send2node(node, VersionMessage())
        version, verack = false, false
        while !(version && verack)
            if bytesavailable(node.sock) > 0
                raw = read(node.sock.buffer)
                if node.logging
                    println("Raw response: \n", bytes2hex(raw))
                end
                envelopes = io2envelope(raw, node.testnet)
                for envelope in envelopes
                    command = envelope.command
                    msg = PARSE_PAYLOAD[command](envelope.payload)
                    if node.logging
                        println("Parsed response: \n", msg)
                    end
                    if command == "version"
                        send2node(node, VerAckMessage())
                        version = true
                    elseif command == "verack"
                        verack = true
                    elseif command == "ping"
                        send2node(node, PongMessage(envelope.payload))
                    end
                end
            else
                sleep(0.01)
            end
        end
        true
    catch e
        println("Failed, error ", e, " was raised.")
        false
    end
end


"""
    getheaders(node::Node, stop::Integer, start::Integer=1) -> Array{BlockHeader,1}

Returns a list of blockheaders, from `start` to `stop` height
!!!Experimental function, not tested as it should
"""
function getheaders(node::Node, stop::Integer, start::Integer=1)
    handshake(node)
    last_block_hash = GENESIS_BLOCK_HASH[node.testnet]
    current_height = start
    result = BlockHeader[]
    while current_height <= stop
        try
            msg = GetHeadersMessage(last_block_hash)
            send2node(node, msg)
            if bytesavailable(node.sock) > 0
                raw = read(node.sock.buffer)
                envelopes = io2envelope(raw, node.testnet)
                for envelope in envelopes
                    if envelope.command == "headers"
                        headers = PARSE_PAYLOAD[envelope.command](envelope.payload)
                        for header in headers.headers
                            if !check_pow(header)
                                error("bad proof of work at block ", id(header))
                            end
                            if (last_block_hash != GENESIS_BLOCK_HASH) && (header.prev_block != last_block_hash)
                                error("discontinuous block at ", id(header))
                            end
                            if current_height % 2016 == 0
                                println(id(header))
                            end
                            last_block_hash = hash(header)
                            current_height += 1
                            push!(result, header)
                            if node.logging
                                println(header)
                            end
                        end
                    end
                end
            else
                sleep(0.01)
            end
        catch e
            if typeof(e) == InterruptException
                return error("Interrupted")
            end
            println("Error ", e, " was raised, retrying...")
            sleep(1)
        end
    end
    result
end
