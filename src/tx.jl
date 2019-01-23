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

abstract type TxComponent end

struct TxIn <: TxComponent
    prev_tx::Array{UInt8,1}
    prev_index::Integer
    script_sig::Script
    sequence::Integer
    TxIn(prev_tx, prev_index, script_sig::Nothing, sequence=b"\xffffffff") = new(prev_tx, prev_index, Script(), sequence)
    TxIn(prev_tx, prev_index, script_sig, sequence=b"\xffffffff") = new(prev_tx, prev_index, script_sig, sequence)
end

# TODO
# function show()
#     return '{}:{}'.format(
#     self.prev_tx.hex(),
#     self.prev_index,
#     )
# end

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


struct TxOut <: TxComponent
    amount::Integer
    script_pubkey::Script
    TxOut(amount, script_pubkey) = new(amount, script_pubkey)
end

# TODO
# function show(args)
#     body
# end

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


struct Tx <: TxComponent
    version::Integer
    tx_ins::Array{TxIn, 1}
    tx_outs::Array{TxOut, 1}
    locktime::Integer
    testnet::Bool
    Tx(version, tx_ins, tx_outs, locktime, testnet=false) = new(version, tx_ins, tx_outs, locktime, testnet)
end

# TODO
# function show()
# end


"""
Takes a byte stream and parses the transaction at the start
return a Tx object
"""
function txparse(s::Base.GenericIOBuffer)
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
