using Test, Bitcoin, ECC, Sockets

tests = ["murmur3", "bloomfilter", "merkle", "address", "op", "script", "helper", "tx", "network", "block", "node"]

for t ∈ tests
  include("$(t)test.jl")
end
