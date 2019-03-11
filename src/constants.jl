# Script

const SIGHASH_ALL = 1
const SIGHASH_NONE = 2
const SIGHASH_SINGLE = 3

const SCRIPT_TYPES = Dict([
    ("P2PKH", [0x6f, 0x00]),
    ("P2SH", [0xc4, 0x05])
])

# Network

const USER_AGENT = read(IOBuffer("/bitcoin.jl:0.1/"))

const DEFAULT = Dict([
    ("version", 70015),
    ("services", 0),
    ("ip", fill(0x00, 4)),
    ("port", Dict([(false, 8333),
                   (true, 18333)])),
    ("rpcport", Dict([(false, 8332),
                   (true, 18332)])),
    ("latest_block", 0),
    ("relay", true)
])
const NODE_URL = "btc.brane.cc"

const TX_DATA_TYPE = 1
const BLOCK_DATA_TYPE = 2
const FILTERED_BLOCK_DATA_TYPE = 3
const COMPACT_BLOCK_DATA_TYPE = 4

"""
NETWORK_MAGIC is testnet if `true`
"""
const NETWORK_MAGIC = Dict([
    (false, [0xf9, 0xbe, 0xb4, 0xd9])
    (true, [0x0b, 0x11, 0x09, 0x07])
])
