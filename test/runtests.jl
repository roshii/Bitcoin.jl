using Test, Bitcoin, ECC, Sockets

tests = ["CompactSizeUInt", "tx", "murmur3", "bloomfilter", "merkle", "address", "op", "script", "helper", "network", "block"]

for t ∈ tests
  include("$(t)test.jl")
end
