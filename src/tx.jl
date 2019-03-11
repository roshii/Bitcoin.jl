using HTTP

struct Fetcher
    cache::Dict{String,Any}
    Fetcher(cache::Nothing) = new(Dict{String,Any}())
    Fetcher(cache) = new(cache)
end

function geturl(testnet::Bool=false)
    string("http://", NODE_URL, ":", DEFAULT["rpcport"][testnet])
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
        if raw[5:6] == [0x00, 0x01]
            deleteat!(raw, 5:6)
            # flag = true # If present, always 0001, and indicates the presence of witness data
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
    fetcher.cache[tx_id].testnet = testnet
    return fetcher.cache[tx_id]
end

abstract type TxComponent end

mutable struct TxIn <: TxComponent
    prev_tx::Array{UInt8,1}
    prev_index::Integer
    script_sig::Script
    sequence::Integer
    TxIn(prev_tx, prev_index) = new(prev_tx, prev_index, Script(nothing), 0xffffffff)
    TxIn(prev_tx, prev_index, script_sig, sequence=0xffffffff) = new(prev_tx, prev_index, script_sig, sequence)
end

function show(io::IO, z::TxIn)
    print(io, "\n", bytes2hex(z.prev_tx), ":", z.prev_index, "\n", z.script_sig)
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
     txoutparse(s::IOBuffer) -> TxOut

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
    txoutserialize(tx::TxOut) -> Array{UInt8,1}

Returns the byte serialization of the transaction output
"""
function txoutserialize(tx::TxOut)
    result = int2bytes(tx.amount, 8, true)
    append!(result, scriptserialize(tx.script_pubkey))
    return result
end

mutable struct Tx <: TxComponent
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
    return Tx(version, inputs, outputs, locktime, testnet)
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
    txsighash256(tx::Tx, input_index::Integer) -> Array{UInt8,1}

Returns the hash that needs to get signed for index input_index
"""
function txsighash256(tx::Tx, input_index::Integer)
    alt_tx_ins = TxIn[]
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
    return hash256(result)
end

"""
    txsighash(tx::Tx, input_index::Integer) -> Integer

Returns the integer representation of the hash that needs to get
signed for index input_index
"""
function txsighash(tx::Tx, input_index::Integer)
    return bytes2int(txsighash256(tx, input_index))
end

"""
Returns whether the input has a valid signature
"""
function txinputverify(tx::Tx, input_index)
    tx_in = tx.tx_ins[input_index + 1]
    z = txsighash(tx, input_index)
    combined_script = Script(copy(tx_in.script_sig.instructions))
    append!(combined_script.instructions,
            txin_scriptpubkey(tx_in, tx.testnet).instructions)
    return scriptevaluate(combined_script, z)
end

"""
Verify this transaction
"""
function txverify(tx::Tx)
    if txfee(tx) < 0
        return false
    end
    for i in 1:length(tx.tx_ins)
        if !txinputverify(tx, i - 1)
            return false
        end
    end
    return true
end


"""
Signs the input using the private key
"""
function txsigninput(tx::Tx, input_index::Integer, private_key::PrivateKey)
    z = txsighash(tx, input_index)
    sig = pksign(private_key, z)
    txpushsignature(tx, input_index, z, sig, private_key.𝑃)
end

"""
Append Signature to the Script Pubkey of TxIn at index
"""
function txpushsignature(tx::Tx, input_index::Integer, z::Integer, sig::Signature, pubkey::S256Point)
    der = sig2der(sig)
    append!(der, int2bytes(SIGHASH_ALL))
    sec = point2sec(pubkey)
    script_sig = Script([der, sec])
    tx.tx_ins[input_index + 1].script_sig = script_sig
    return txinputverify(tx, input_index)
end

"""
Returns whether this transaction is a coinbase transaction or not
"""
function iscoinbase(tx::Tx)
    if length(tx.tx_ins) != 1
        return false
    end
    input = tx.tx_ins[1]
    if input.prev_tx != fill(0x00, 32) || input.prev_index != 0xffffffff
        return false
    end
    return true
end

"""
Returns the height of the block this coinbase transaction is in
Returns `nothing` if this transaction is not a coinbase transaction
"""
function coinbase_height(tx::Tx)
    if !iscoinbase(tx)
        return nothing
    end
    height_bytes = tx.tx_ins[1].script_sig.instructions[1]
    return bytes2int(height_bytes, true)
end
