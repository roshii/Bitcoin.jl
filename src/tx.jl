using HTTP
import Base: hash, parse, fetch
import ECC.verify

function geturl(testnet::Bool=false)
    string("http://", NODE_URL, ":", DEFAULT["rpcport"][testnet])
end

"""
    fetch(tx_id::String, testnet::Bool=false) -> Tx

Returns the bitcoin transaction given its ID as an hexadecimal string.
"""
function fetch(tx_id::String, testnet::Bool=false)
    url = string(geturl(testnet), "/rest/tx/", tx_id, ".bin")
    response = HTTP.request("GET", url)
    try
        response.status == 200
    catch
        error("Unexpected status: ", response.status)
    end
    raw = response.body
    tx = parse(IOBuffer(raw), testnet)
    if tx.segwit
        computed = id(tx)
    else
        computed = bytes2hex(reverse!(copy(hash256(raw))))
    end
    if id(tx) != tx_id
        error("not the same id : ", id(tx),
            "\n             vs : ", tx_id)
    end
    return tx
end

abstract type TxComponent end

mutable struct TxIn <: TxComponent
    prev_tx::Vector{UInt8}
    prev_index::UInt32
    script_sig::Script
    witness::Script
    sequence::UInt32
    TxIn(prev_tx, prev_index) = new(prev_tx, prev_index, Script(nothing), Script(nothing), 0xffffffff)
    TxIn(prev_tx, prev_index, script_sig::Script, sequence::Integer=0xffffffff) = new(prev_tx, prev_index, script_sig, Script(nothing), sequence)
    TxIn(prev_tx, prev_index, script_sig::Script, witness::Script, sequence::Integer=0xffffffff) = new(prev_tx, prev_index, script_sig, witness, sequence)
end

function show(io::IO, z::TxIn)
    print(io, "\n", bytes2hex(z.prev_tx), ":", z.prev_index, "\n", z.script_sig)
end

"""
Takes a byte stream and parses the tx_input at the start
return a TxIn object
"""
function txinparse(s::IOBuffer)
    prev_tx = read(s, 32)
    reverse!(prev_tx)
    bytes = read(s, 4)
    prev_index = bytes2int(bytes, true)
    script_sig = scriptparse(s)
    readbytes!(s, bytes, 4)
    sequence = bytes2int(bytes, true)
    return TxIn(prev_tx, prev_index, script_sig, sequence)
end

"""
    serialize(tx::TxIn) -> Vector{UInt8}

Returns the byte serialization of the transaction input
"""
function serialize(tx::TxIn)
    result = copy(tx.prev_tx)
    reverse!(result)
    append!(result, int2bytes(tx.prev_index, 4, true))
    append!(result, serialize(tx.script_sig))
    append!(result, int2bytes(tx.sequence, 4, true))
    return result
end

function fetch(tx::TxIn, testnet::Bool=false)
    return fetch(bytes2hex(tx.prev_tx), testnet)
end

"""
    value(txin::TxIn, testnet::Bool=false) ->

Get the outpoint value by looking up the tx hash
Returns the amount in satoshi
"""
function value(txin::TxIn, testnet::Bool=false)
    tx = fetch(txin, testnet)
    return tx.tx_outs[txin.prev_index + 1].amount
end

"""
    script_pubkey(txin::TxIn, testnet::Bool=false)
    -> Script

Get the scriptPubKey by looking up the tx hash
Returns a Script object
"""
function script_pubkey(txin::TxIn, testnet::Bool=false)
    tx = fetch(txin, testnet)
    return tx.tx_outs[txin.prev_index + 1].script_pubkey
end

struct TxOut <: TxComponent
    amount::UInt64
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
    serialize(tx::TxOut) -> Vector{UInt8}

Returns the byte serialization of the transaction output
"""
function serialize(tx::TxOut)
    result = int2bytes(tx.amount, 8, true)
    append!(result, serialize(tx.script_pubkey))
    return result
end

mutable struct Tx <: TxComponent
    version::UInt32
    tx_ins::Vector{TxIn}
    tx_outs::Vector{TxOut}
    locktime::UInt32
    testnet::Bool
    segwit::Bool
    flag::UInt8
    _hash_prevouts
    _hash_sequence
    _hash_outputs
    Tx(version::Integer, tx_ins, tx_outs, locktime::Integer, testnet=false, segwit=false, flag=0x00) = new(UInt32(version), tx_ins, tx_outs, UInt32(locktime), testnet, segwit, flag, nothing, nothing, nothing)
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

function parse_legacy(s::Base.GenericIOBuffer, testnet::Bool=false)
    version = ltoh(reinterpret(UInt32, read(s, 4))[1])
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
    locktime = ltoh(reinterpret(UInt32, read(s, 4))[1])
    return Tx(version, inputs, outputs, locktime, testnet)
end

function parse_segwit(s::Base.GenericIOBuffer, testnet::Bool=false)
    version = ltoh(reinterpret(UInt32, read(s, 4))[1])
    flag = read(s, 2)[2]
    num_inputs = read_varint(s)
    inputs = []
    for _ ∈ 1:num_inputs
        push!(inputs, txinparse(s))
    end
    num_outputs = read_varint(s)
    outputs = []
    for _ ∈ 1:num_outputs
        push!(outputs, txoutparse(s))
    end
    for tx_in ∈ inputs
        items = []
        num_items = read_varint(s)
        for _ in 1:num_items
            item_len = read_varint(s)
            if item_len == 0
                push!(items, 0)
            else
                push!(items, read(s, item_len))
            end
        end
        tx_in.witness.instructions = items
    end
    locktime = ltoh(reinterpret(UInt32, read(s, 4))[1])
    Tx(version, inputs, outputs, locktime,
    testnet, true, flag)
end

function parse(s::IOBuffer, testnet::Bool=false)::Tx
    if read(s, 5)[5] == 0x00
        f = parse_segwit
    else
        f = parse_legacy
    end
    seekstart(s)
    f(s, testnet)
end

function payload2tx(payload::Vector{UInt8})
    txparse(IOBuffer(payload))
end

"""
    serialize(tx::Tx) -> Vector{UInt8}

Returns the byte serialization of the transaction
"""
serialize(tx::Tx) = tx.segwit ? serialize_segwit(tx) : serialize_legacy(tx)


function serialize_legacy(tx::Tx)
    result = int2bytes(tx.version, 4, true)
    append!(result, encode_varint(length(tx.tx_ins)))
    for tx_in in tx.tx_ins
        append!(result, serialize(tx_in))
    end
    append!(result, encode_varint(length(tx.tx_outs)))
    for tx_out in tx.tx_outs
        append!(result, serialize(tx_out))
    end
    append!(result, int2bytes(tx.locktime, 4, true))
    return result
end

function serialize_segwit(tx::Tx)
    result = int2bytes(tx.version, 4, true)
    append!(result, [0x00, tx.flag])
    append!(result, encode_varint(length(tx.tx_ins)))
    for tx_in in tx.tx_ins
        append!(result, serialize(tx_in))
    end
    append!(result, encode_varint(length(tx.tx_outs)))
    for tx_out in tx.tx_outs
        append!(result, serialize(tx_out))
    end
    for tx_in in tx.tx_ins
        append!(result, UInt8(length(tx_in.witness.instructions)))
        for item in tx_in.witness.instructions
            if typeof(item) <: Vector
                append!(result, encode_varint(length(item)))
            end
            append!(result, item)
        end
    end
    append!(result, int2bytes(tx.locktime, 4, true))
    return result
end

"""
Binary hash of the legacy serialization
"""
function hash(tx::Tx)
    return reverse(hash256(serialize_legacy(tx)))
end

"""
    id(tx::Tx) -> String

Returns an hexadecimal string of the transaction hash
"""
function id(tx::Tx)
    return bytes2hex(hash(tx))
end

"""
    fee(tx::Tx) -> Integer

Returns the fee of this transaction in satoshi
"""
function fee(tx::Tx)
    input_sum, output_sum = 0, 0
    for tx_in in tx.tx_ins
        input_sum += value(tx_in, tx.testnet)
    end
    for tx_out in tx.tx_outs
        output_sum += tx_out.amount
    end
    return input_sum - output_sum
end

"""
    sig_hash(tx::Tx, input_index::Integer)::Vector{UInt8}

Returns the hash that needs to get signed for index input_index
"""
function sig_hash(tx::Tx, input_index::Integer, redeem_script::Union{Script,Nothing}=nothing)
    s = Vector(reinterpret(UInt8, [htol(tx.version)]))
    append!(s, encode_varint(length(tx.tx_ins)))

    i, script_sig = 0, Script(nothing)
    for tx_in in tx.tx_ins
        if i == input_index
            if redeem_script != nothing
                script_sig = redeem_script
            else
                script_sig = script_pubkey(tx_in, tx.testnet)
            end
        else
            script_sig = nothing
        end
        alt_tx_in = TxIn(tx_in.prev_tx,
                         tx_in.prev_index,
                         script_sig,
                         tx_in.sequence)

        append!(s, serialize(alt_tx_in))
    end
    append!(s, encode_varint(length(tx.tx_outs)))
    for tx_out in tx.tx_outs
        append!(s, serialize(tx_out))
    end
    append!(s, Vector(reinterpret(UInt8, [htol(tx.locktime)])))
    append!(s, Vector(reinterpret(UInt8, [htol(SIGHASH_ALL)])))
    return hash256(s)
end

function hash_prevouts(tx::Tx)
    if tx._hash_prevouts == nothing
        all_prevouts = UInt8[]
        all_sequence = UInt8[]
        for tx_in in tx.tx_ins
            append!(all_prevouts, reverse!(copy(tx_in.prev_tx)))
            append!(all_prevouts, reinterpret(UInt8, [htol(tx_in.prev_index)]))
            append!(all_sequence, reinterpret(UInt8, [htol(tx_in.sequence)]))
            tx._hash_prevouts = hash256(all_prevouts)
            tx._hash_sequence = hash256(all_sequence)
        end
    end
    return tx._hash_prevouts
end

function hash_sequence(tx::Tx)
    if tx._hash_sequence == nothing
        hash_prevouts(tx)
    end
    return tx._hash_sequence
end

function hash_outputs(tx::Tx)
    if tx._hash_outputs == nothing
        all_outputs = UInt8[]
        for tx_out in tx.tx_outs
            append!(all_outputs, serialize(tx_out))
        end
        tx._hash_outputs = hash256(all_outputs)
    end
    return tx._hash_outputs
end


"""
Returns the integer representation of the hash that needs to get
signed for index input_index
"""
function sig_hash_bip143(tx::Tx, input_index::Integer; redeem_script::Union{Script,Nothing}=nothing, witness_script::Union{Script,Nothing}=nothing)
    tx_in = tx.tx_ins[input_index+1]
    # per BIP143 spec
    s = Vector(reinterpret(UInt8, [htol(tx.version)]))
    append!(s, hash_prevouts(tx))
    append!(s, hash_sequence(tx))
    append!(s, reverse!(copy(tx_in.prev_tx)))
    append!(s, reinterpret(UInt8, [htol(tx_in.prev_index)]))

    if witness_script != nothing
        script_code = serialize(witness_script)
    elseif redeem_script != nothing
        script_code = serialize(p2pkh_script(redeem_script.instructions[2]))
    else
        script_code = serialize(p2pkh_script(script_pubkey(tx_in, tx.testnet).instructions[2]))
    end
    append!(s, script_code)
    append!(s, reinterpret(UInt8, [htol(value(tx_in, tx.testnet))]))
    append!(s, reinterpret(UInt8, [htol(tx_in.sequence)]))
    append!(s, hash_outputs(tx))
    append!(s, reinterpret(UInt8, [htol(tx.locktime)]))
    append!(s, reinterpret(UInt8, [htol(SIGHASH_ALL)]))

    return hash256(s)
end

"""
    verify(tx::Tx, input_index) -> Bool

Returns whether the input has a valid signature
"""
function verify(tx::Tx, input_index)
    tx_in = tx.tx_ins[input_index+1]
    script_pubkey_ = script_pubkey(tx_in, tx.testnet)
    if is_p2sh(script_pubkey_)
        raw_redeem = copy(tx_in.script_sig.instructions[end])
        length_ = UInt8(length(raw_redeem))
        pushfirst!(raw_redeem, length_)
        redeem_script = scriptparse(IOBuffer(raw_redeem))
        if is_p2wpkh(redeem_script)
            z = sig_hash_bip143(tx, input_index, redeem_script=redeem_script)
            witness = tx_in.witness
        elseif is_p2wsh(redeem_script)
            raw_witness = copy(tx_in.witness.instructions[end])
            length_ = encode_varint(length(raw_witness))
            prepend!(raw_witness, length_)
            witness_script = scriptparse(IOBuffer(raw_witness))
            z = sig_hash_bip143(tx, input_index, witness_script=witness_script)
            witness = tx_in.witness
        else
            z = sig_hash(tx, input_index, redeem_script)
            witness = nothing
        end
    else
        if is_p2wpkh(script_pubkey_)
            z = sig_hash_bip143(tx, input_index)
            witness = tx_in.witness
        elseif is_p2wsh(script_pubkey_)
            raw_witness = copy(tx_in.witness.instructions[end])
            length_ = encode_varint(length(raw_witness))
            prepend!(raw_witness, length_)
            witness_script = scriptparse(IOBuffer(raw_witness))
            z = sig_hash_bip143(tx, input_index, witness_script=witness_script)
            witness = tx_in.witness
        else
            z = sig_hash(tx, input_index)
            witness = nothing
        end
    end
    combined_script = Script(copy(tx_in.script_sig.instructions))
    append!(combined_script.instructions, script_pubkey(tx_in, tx.testnet).instructions)
    return evaluate(combined_script, bytes2int(z), witness)
end


"""
    verify(tx::Tx) -> Bool

Verify transaction `tx`
"""
function verify(tx::Tx)
    if fee(tx) < 0
        return false
    end
    for i in 1:length(tx.tx_ins)
        if !verify(tx, i - 1)
            return false
        end
    end
    return true
end

"""
Signs the input using the private key
"""
function txsigninput(tx::Tx, input_index::Integer, private_key::PrivateKey)
    z = bytes2int(sig_hash(tx, input_index))
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
    return verify(tx, input_index)
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

@deprecate txparse(s::IOBuffer, testnet::Bool) parse(s::IOBuffer, testnet::Bool)::Tx
@deprecate txserialize(tx::Tx) serialize_legacy(tx::Tx)
@deprecate txoutserialize(tx::TxOut) serialize(tx::TxOut)
@deprecate txhash(tx::Tx) hash(tx::Tx)
@deprecate txinputverify(tx::Tx, input_index) verify(tx::Tx, input_index)
@deprecate txinvalue(txin::TxIn, testnet::Bool) value(txin::TxIn, testnet::Bool)
@deprecate txverify(tx::Tx) verify(tx::Tx)
@deprecate txid(tx::Tx) id(tx::Tx)
@deprecate txfee(tx::Tx) fee(tx::Tx)
@deprecate txsighash256(tx::Tx, input_index::Integer) sig_hash(tx::Tx, input_index::Integer)
@deprecate txin_scriptpubkey(txin::TxIn, testnet::Bool) script_pubkey(txin::TxIn, testnet::Bool)
@deprecate txinserialize(tx::TxIn) serialize(tx::TxIn)
@deprecate txin_fetchtx(tx::TxIn, testnet::Bool) fetch(tx::TxIn, testnet::Bool)
@deprecate txfetch(tx_id::String, testnet::Bool) fetch(tx_id::String, testnet::Bool)
