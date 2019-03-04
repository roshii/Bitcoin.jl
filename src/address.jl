const ADDRESS_PREFIX = Dict([
    ("P2PKH", [0x6f, 0x00]),
    ("P2SH", [0xc4, 0x05])
])

"""
    Array{UInt8,1} -> String

Returns a String representing a Bitcoin address
"""
function h160_2_address(h160::Array{UInt8,1}, testnet::Bool=false, type::String="P2SH")
    testnet ? i = 1 : i = 2
    result = copy(h160)
    result = pushfirst!(result, ADDRESS_PREFIX[type][i])
    return String(base58checkencode(result))
end

"""
    adress(P::ECC.S256Point, compressed::Bool, testnet::Bool) -> String

Returns the Base58 Bitcoin address given an S256Point
Compressed is set to true if not provided.
Testnet is set to false by default.
"""
function address(P::T, compressed::Bool=true, testnet::Bool=false) where {T<:S256Point}
    s = point2sec(P, compressed)
    h160 = ripemd160(sha256(s))
    return h160_2_address(h160, testnet, "P2PKH")
end

"""
    wif(pk::PrivateKey, compressed::Bool=true, testnet::Bool=false) -> String

Returns a PrivateKey in Wallet Import Format
Compressed is set to true if not provided.
Testnet is set to false by default.
"""
function wif(pk::PrivateKey, compressed::Bool=true, testnet::Bool=false)
    secret_bytes = int2bytes(pk.𝑒)
    if testnet
        prefix = 0xef
    else
        prefix = 0x80
    end
    result = pushfirst!(secret_bytes, prefix)
    if compressed
        return String(base58checkencode(push!(result, 0x01)))
    else
        return String(base58checkencode(result))
    end
end
