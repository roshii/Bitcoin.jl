using Test, Bitcoin, ECC, Sockets

tests = ["merkle", "address", "op", "script", "helper", "tx", "network", "block", "node"]

for t ∈ tests
  include("$(t)test.jl")
end
