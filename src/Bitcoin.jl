module Bitcoin

using ECC, Base58
using SHA: sha1, sha256
using Ripemd: ripemd160
using Dates: unix2datetime, datetime2unix, now
using Sockets
import Base.show
export CompactSizeUInt
export Tx, TxIn, TxOut, Script, BlockHeader,
       VersionMessage, GetHeadersMessage, GetDataMessage,
       Node, BloomFilter
export address, wif, parse, serialize, id, fee, sig_hash,
       evaluate, fetch, verify, txsigninput,
       h160_2_address, script2address,
       iscoinbase, coinbase_height,
       blockparse, target, difficulty, check_pow, txoutparse

include("helper.jl")
include("CompactSizeUInt.jl")
include("constants.jl")
include("address.jl")
include("op.jl")
include("script.jl")
include("tx.jl")
include("Block.jl")
include("BloomFilter.jl")
include("network.jl")
include("Node.jl")
include("MerkleTree.jl")
include("murmur3.jl")

end # module
