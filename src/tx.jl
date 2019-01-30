"""
    This file is part of Bitcoin.jl

    Bitcoin.jl is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    Bitcoin.jl is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Bitcoin.jl.  If not, see <https://www.gnu.org/licenses/>.
"""

using HTTP

struct Fetcher
    cache::Dict{String,Any}
    Fetcher(cache::Nothing) = new(Dict{String,Any}())
    Fetcher(cache) = new(cache)
end

function geturl(testnet::Bool=false)
    if testnet
        return "http://tbtc.brane.cc:18332"
    else
        return "http://btc.brane.cc:8332"
    end
end

function txfetch(tx_id, testnet::Bool=false, fresh::Bool=false, fetcher::Fetcher=Fetcher(nothing))
    if fresh || !haskey(fetcher.cache, tx_id)
        url = string(geturl(testnet), "/rest/tx/", tx_id, ".bin")
        response = HTTP.request("GET", url)
        try
            response.status == 200
        catch
            error("Unexpected status: ", response.status)
        end
        raw = response.body
        if raw[5] == 0
            splice!(raw, 6)
            tx = txparse(IOBuffer(raw), testnet)
            tx.locktime = bytes2int(raw[end-3:end], true)
        else
            tx = txparse(IOBuffer(raw), testnet)
        end
        # make sure the tx we got matches to the hash we requested
        if txid(tx) != tx_id
            error("not the same id : ", txid(tx),
                "\n             vs : ", tx_id)
        end
        fetcher.cache[tx_id] = tx
    end
    # fetcher.cache[tx_id].testnet = testnet
    return fetcher.cache[tx_id]
end

abstract type TxComponent end

struct TxIn <: TxComponent
    prev_tx::Array{UInt8,1}
    prev_index::Integer
    script_sig::Script
    sequence::Integer
    TxIn(prev_tx, prev_index) = new(prev_tx, prev_index, Script(nothing))
    TxIn(prev_tx, prev_index, script_sig, sequence=b"\xffffffff") = new(prev_tx, prev_index, script_sig, sequence)
end

function show(io::IO, z::TxIn)
    print(io, "\n", bytes2hex(z.prev_tx), ":", z.prev_index)
end

"""
Takes a byte stream and parses the tx_input at the start
return a TxIn object
"""
function txinparse(s::Base.GenericIOBuffer)
    prev_tx = UInt8[]
    readbytes!(s, prev_tx, 32)
    reverse!(prev_tx)
    bytes = UInt8[]
    readbytes!(s, bytes, 4)
    prev_index = bytes2int(bytes, true)
    script_sig = scriptparse(s)
    readbytes!(s, bytes, 4)
    sequence = bytes2int(bytes, true)
    return TxIn(prev_tx, prev_index, script_sig, sequence)
end

"""
Returns the byte serialization of the transaction input
"""
function txinserialize(tx::TxIn)
    result = tx.prev_tx
    reverse!(result)
    append!(result, int2bytes(tx.prev_index, 4, true))
    append!(result, scriptserialize(tx.script_sig))
    append!(result, int2bytes(tx.sequence, 4, true))
    return result
end

function txin_fetchtx(tx::TxIn, testnet::Bool=false)
    return txfetch(bytes2hex(tx.prev_tx), testnet)
end

"""
Get the outpoint value by looking up the tx hash
Returns the amount in satoshi
"""
function txinvalue(txin::TxIn, testnet::Bool=false)
    tx = txin_fetchtx(txin, testnet)
    return tx.tx_outs[txin.prev_index].amount
end


struct TxOut <: TxComponent
    amount::Integer
    script_pubkey::Script
    TxOut(amount, script_pubkey) = new(amount, script_pubkey)
end

function show(io::IO, z::TxOut)
    print(io, "\n", z.script_pubkey, "\namout (BTC) : ", z.amount / 100000000)
end

"""
Takes a byte stream and parses the tx_output at the start
return a TxOut object
"""
function txoutparse(s::Base.GenericIOBuffer)
    bytes = UInt8[]
    readbytes!(s, bytes, 8)
    amount = bytes2int(bytes, true)
    script_pubkey = scriptparse(s)
    return TxOut(amount, script_pubkey)
end

"""
Returns the byte serialization of the transaction output
"""
function txoutserialize(tx::TxOut)
    result = int2bytes(tx.amount, 8, true)
    append!(result, scriptserialize(tx.script_pubkey))
    return result
end

struct Tx <: TxComponent
    version::Integer
    tx_ins::Array{TxIn, 1}
    tx_outs::Array{TxOut, 1}
    locktime::Integer
    testnet::Bool
    Tx(version, tx_ins, tx_outs, locktime, testnet=false) = new(version, tx_ins, tx_outs, locktime, testnet)
end

function show(io::IO, z::Tx)
    print(io, "Transaction\n--------\nTestnet : ", z.testnet,
            "\nVersion : ", z.version,
            "\nLocktime : ", z.locktime,
            "\n--------\n",
            "\n", z.tx_ins,
            "\n--------\n",
            "\n", z.tx_outs)
end

"""
Takes a byte stream and parses the transaction at the start
return a Tx object
"""
function txparse(s::Base.GenericIOBuffer, testnet::Bool=false)
    bytes = UInt8[]
    readbytes!(s, bytes, 4)
    version = bytes2int(bytes, true)
    num_inputs = read_varint(s)
    inputs = []
    for i in 1:num_inputs
        push!(inputs, txinparse(s))
    end
    num_outputs = read_varint(s)
    outputs = []
    for i in 1:num_outputs
        push!(outputs, txoutparse(s))
    end
    readbytes!(s, bytes, 4)
    locktime = bytes2int(bytes, true)
    return Tx(version, inputs, outputs, locktime)
end

"""
Returns the byte serialization of the transaction
"""
function txserialize(tx::Tx)
    result = int2bytes(tx.version, 4, true)
    append!(result, encode_varint(length(tx.tx_ins)))
    for tx_in in tx.tx_ins
        append!(result, txinserialize(tx_in))
    end
    append!(result, encode_varint(length(tx.tx_outs)))
    for tx_out in tx.tx_outs
        append!(result, txoutserialize(tx_out))
    end
    append!(result, int2bytes(tx.locktime, 4, true))
    return result
end


"""
Binary hash of the legacy serialization
"""
function txhash(tx::Tx)
    return reverse(sha256(sha256(txserialize(tx))))
end

"""
Human-readable hexadecimal of the transaction hash
"""
function txid(tx::Tx)
    return bytes2hex(txhash(tx))
end
