using HTTP
import Base: fetch, get

function geturl(testnet::Bool=false)
    string("http://", NODE_URL, ":", DEFAULT["rpcport"][testnet])
end

"""
    get(url::String, key::String; testnet::Bool)
    -> Tx

Returns the bitcoin transaction given a node url with REST server enabled and
transaction hash as an hexadecimal string.
Uses mainnet by default
"""
function gettx(url::String, key::String; testnet::Bool=false)
    url *= "/rest/tx/" * key * ".bin"
    response = HTTP.request("GET", url)
    try
        response.status == 200
    catch
        error("Unexpected status: ", response.status)
    end
    raw = response.body
    tx = parse(IOBuffer(raw), testnet)::Tx
    if tx.segwit
        computed = id(tx)
    else
        computed = bytes2hex(reverse!(copy(hash256(raw))))
    end
    if id(tx) != key
        error("not the same id : ", id(tx),
            "\n             vs : ", tx_id)
    end
    return tx
end

"""
    get(url::String, key::String, testnet::Bool=false)
    -> BlockHeaders[]

Returns the bitcoin transaction given a node url with REST server enabled and
transaction hash as an hexadecimal string.
"""
function getheaders(url::String, key::String; amount::Integer=1, testnet::Bool=false)
    url *= "/rest/headers/" * string(amount) * "/" * key * ".bin"
    response = HTTP.request("GET", url)
    try
        response.status == 200
    catch
        error("Unexpected status: ", response.status)
    end
    io = IOBuffer(response.body)
    headers = BlockHeader[]
    while io.ptr < io.size
        push!(headers, io2blockheader(io))
    end
    return headers
end

@deprecate txfetch(tx_id::String, testnet::Bool=false) fetch(tx_id::String, testnet::Bool)
@deprecate fetch(tx_id::String, testnet::Bool=false) gettx(geturl(testnet), tx_id, testnet=testnet)
