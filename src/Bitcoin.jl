module Bitcoin

using ECC, Base58
using SHA: sha1, sha256
using Ripemd: ripemd160
export Tx, TxIn, TxOut, Script
export address, wif, txparse, txserialize, txid, txfee, txsighash,
       scriptevaluate, txfetch, txverify, txsigninput

const SIGHASH_ALL = 1
const SIGHASH_NONE = 2
const SIGHASH_SINGLE = 3

include("helper.jl")
include("address.jl")
include("op.jl")
include("script.jl")
include("tx.jl")

end # module
