using ECC, SHA, Dates, Sockets
import Base: show

include("src/helper.jl")
include("src/constants.jl")
include("src/address.jl")
include("src/op.jl")
include("src/script.jl")
include("src/tx.jl")
include("src/Block.jl")
include("src/network.jl")
include("src/Node.jl")

node = Node("btc.brane.cc", 8333, false, true)

"""
Returns a list of start::Integer, blockheaders, from `start` to `stop` height
"""
function getheaders(node::Node, stop::Integer, start::Integer=1)
    handshake(node)
    last_block_hash = GENESIS_BLOCK_HASH[node.testnet]
    current_height = start
    # headers = Array{BlockHeader}(undef, stop - start + 1)
    while current_height < stop
        try
            response = Channel(read_node)
            msg = GetHeadersMessage(last_block_hash)
            send2node(node, msg)
            raw = take!(response)
            println("Raw response: \n", raw)
            envelope = io2envelope(raw, node.testnet)
            msg = PARSE_PAYLOAD[envelope.command](envelope.payload)
            println("Parsed response: \n", msg)
            current_height += 1
            last_block_hash = hash(headers[i])
        catch e
            if typeof(e) == InterruptException
                return error("Interrupted")
            end
            println("Error ", e, " was raised, retrying...")
        end
    end
    # for header in headers.headers
    #     if !check_pow(header)
    #         error("bad proof of work at block ", id(header))
    #     end
    #     if (last_block_hash != GENESIS_BLOCK_HASH) && (header.prev_block != last_block_hash)
    #         error("discontinuous block at ", id(header))
    #     end
    #     if current_height % 2016 == 0
    #         println(id(header))
    #     end
    # end
end

msg = hex2bytes("0b11090776657273696f6e00000000006600000016a4efe07f11010000000000000000008dc0905c00000000000000000000000000000000000000000000ffff00000000479d000000000000000000000000000000000000ffff00000000479d953c16b39c5d6e1f102f626974636f696e2e6a6c3a302e312f0000000001")
