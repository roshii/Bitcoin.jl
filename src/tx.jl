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

"""
    txfetch(tx_id::String) -> Tx

Returns the bitcoin transaction given its ID as an hexadecimal string.
"""
function txfetch(tx_id::String, testnet::Bool=false, fresh::Bool=false, fetcher::Fetcher=Fetcher(nothing))
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

mutable struct TxIn <: TxComponent
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
    # s = IOBuffer(hex2bytes("c228021e1fee6f158cc506edea6bad7ffa421dd14fb7fd7e01c50cc9693e8dbe02000000fdfe0000483045022100c679944ff8f20373685e1122b581f64752c1d22c67f6f3ae26333aa9c3f43d730220793233401f87f640f9c39207349ffef42d0e27046755263c0a69c436ab07febc01483045022100eadc1c6e72f241c3e076a7109b8053db53987f3fcc99e3f88fc4e52dbfd5f3a202201f02cbff194c41e6f8da762e024a7ab85c1b1616b74720f13283043e9e99dab8014c69522102b0c7be446b92624112f3c7d4ffc214921c74c1cb891bf945c49fbe5981ee026b21039021c9391e328e0cb3b61ba05dcc5e122ab234e55d1502e59b10d8f588aea4632102f3bd8f64363066f35968bd82ed9c6e8afecbd6136311bb51e91204f614144e9b53aeffffffff05a08601000000000017a914081fbb6ec9d83104367eb1a6a59e2a92417d79298700350c00000000001976a914677345c7376dfda2c52ad9b6a153b643b6409a3788acc7f341160000000017a914234c15756b9599314c9299340eaabab7f1810d8287c02709000000000017a91469be3ca6195efcab5194e1530164ec47637d44308740420f00000000001976a91487fadba66b9e48c0c8082f33107fdb01970eb80388ac00000000"))
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
    result = copy(tx.prev_tx)
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
    return tx.tx_outs[txin.prev_index + 1].amount
end

"""
Get the scriptPubKey by looking up the tx hash
Returns a Script object
"""
function txin_scriptpubkey(txin::TxIn, testnet::Bool=false)
    tx = txin_fetchtx(txin, testnet)
    return tx.tx_outs[txin.prev_index + 1].script_pubkey
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
    txparse(s::Base.GenericIOBuffer, testnet::Bool=false) -> Tx

Returns a Tx object given a byte stream
"""
function txparse(s::Base.GenericIOBuffer, testnet::Bool=false)
    bytes = UInt8[]
    readbytes!(s, bytes, 4)
    version = bytes2int(bytes, true)
    num_inputs = read_varint(s)
    inputs = []
    for i in 1:num_inputs
        input = txinparse(s)
        push!(inputs, input)
    end
    num_outputs = read_varint(s)
    outputs = []
    for i in 1:num_outputs
        output = txoutparse(s)
        push!(outputs, output)
    end
    readbytes!(s, bytes, 4)
    locktime = bytes2int(bytes, true)
    return Tx(version, inputs, outputs, locktime)
end

"""
    txserialize(tx::Tx) -> Array{UInt8,1}

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
    return reverse(hash256(txserialize(tx)))
end

"""
    txid(tx::Tx) -> String

Returns an hexadecimal string of the transaction hash
"""
function txid(tx::Tx)
    return bytes2hex(txhash(tx))
end

"""
    txfee(tx::Tx) -> Integer

Returns the fee of this transaction in satoshi
"""
function txfee(tx::Tx)
    input_sum, output_sum = 0, 0
    for tx_in in tx.tx_ins
        input_sum += txinvalue(tx_in, tx.testnet)
    end
    for tx_out in tx.tx_outs
        output_sum += tx_out.amount
    end
    return input_sum - output_sum
end

"""
    txsighash(tx::Tx, input_index::Integer) -> Integer

Returns the integer representation of the hash that needs to get
signed for index input_index
"""
function txsighash(tx::Tx, input_index::Integer)
    alt_tx_ins = Array{TxIn, 1}()
    for tx_in in tx.tx_ins
        alt_tx_in = TxIn(tx_in.prev_tx, tx_in.prev_index, Script(nothing), tx_in.sequence)
        push!(alt_tx_ins, alt_tx_in)
    end
    signing_input = alt_tx_ins[input_index + 1]
    script_pubkey = txin_scriptpubkey(signing_input, tx.testnet)
    signing_input.script_sig = script_pubkey
    alt_tx = Tx(
        tx.version,
        alt_tx_ins,
        tx.tx_outs,
        tx.locktime)
    result = UInt8[]
    append!(result, txserialize(alt_tx))
    append!(result, int2bytes(SIGHASH_ALL, 4, true))
    h256 = hash256(result)
    return bytes2int(h256)
end
