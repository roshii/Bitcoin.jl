module Bitcoin

using ECC, Base58
using SHA: sha1, sha256
using Ripemd: ripemd160
using Dates: unix2datetime, datetime2unix, now
using Sockets
import Base.show
export Tx, TxIn, TxOut, Script, BlockHeader,
       VersionMessage, GetHeadersMessage
export address, wif, txparse, txserialize, txid, txfee, txsighash,
       scriptevaluate, txfetch, txverify, txsigninput,
       h160_2_address, script2address,
       iscoinbase, coinbase_height,
       blockparse, target, difficulty, check_pow, txoutparse

const USER_AGENT = read(IOBuffer("/bitcoin.jl:0.1/"))

const SIGHASH_ALL = 1
const SIGHASH_NONE = 2
const SIGHASH_SINGLE = 3

const SCRIPT_TYPES = Dict([
    ("P2PKH", [0x6f, 0x00]),
    ("P2SH", [0xc4, 0x05])
])

include("helper.jl")
include("address.jl")
include("op.jl")
include("script.jl")
include("tx.jl")
include("Block.jl")
include("network.jl")

end # module
