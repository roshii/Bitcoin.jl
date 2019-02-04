"""
    adress(P::ECC.S256Point, compressed::Bool, testnet::Bool) -> String

Returns the Base58 Bitcoin address given an S256Point
Compressed is set to true if not provided.
Testnet is set to false by default.
"""
function address(P::T, compressed::Bool=true, testnet::Bool=false) where {T<:S256Point}
    s = point2sec(P, compressed)
    h160 = ripemd160(sha256(s))
    if testnet
        prefix = 0x6f
    else
        prefix = 0x00
    end
    result = pushfirst!(h160, prefix)
    return String(base58checkencode(result))
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
