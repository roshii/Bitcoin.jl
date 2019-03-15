using Sockets
import Sockets.connect, Base.close

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
    connect(node::Node) -> TCPSocket

Connect to the host `node.host` on port `node.port`.
"""
function connect(node::Node)
    try
        if node.sock.status == 6
            node.sock = connect(node.host, node.port)
        end
    catch
        node.sock = connect(node.host, node.port)
    end
end

"""
Close Node TCPSocket
"""
function close(node::Node)
    close(node.sock)
end

"""
    Node, AbstractMessage -> Task

Send a message to the connected node
"""
function send2node(node::Node, message::T) where {T<:AbstractMessage}
    envelope = NetworkEnvelope(message.command,
                               serialize(message),
                               node.testnet)
    if node.logging
        println("sending: ", envelope)
    end
    connect(node)
    write(node.sock, serialize(envelope))
end


"""
Wait for one of the messages in the list
"""
function read_node!(node::Node, expected::String, result::Any)
    command = ""
    while command != expected
        line = read(node.sock)
        # println(bytes2hex(line))
        envelope = io2envelope(line, node.testnet)
        # println(envelope)
        command = envelope.command
        msg = PARSE_PAYLOAD[command](envelope.payload)
        println(msg)
        if command == "version"
            println("sending verack")
            send2node(node, VerAckMessage())
        elseif command == "ping"
            send2node(node, PongMessage(envelope.payload))
            println("sending pong")
        end
        push!(result, msg)
    end
end

"""
handshake(node::Node) -> Array{AbstractMessage,1}

Do a handshake with the other node.
Handshake is sending a version message and getting a verack back.
"""
function handshake(node::Node)
    result = []
    @sync begin
        connect(node)
        @async read_node!(node, "version", result)
        @async send2node(node, VersionMessage())
    end
    close(node)
    result
end
