module Bitcoin

using ECC
using SHA: sha1, sha256
using Ripemd: ripemd160
using Base58: base58checkencode
export Tx, TxIn, TxOut, Script
export address, wif, txparse, txserialize, txid, txfee, txsighash, scriptevaluate, txfetch

const SIGHASH_ALL = 1
const SIGHASH_NONE = 2
const SIGHASH_SINGLE = 3

include("helper.jl")
include("address.jl")
include("op.jl")
include("script.jl")
include("tx.jl")

end # module
