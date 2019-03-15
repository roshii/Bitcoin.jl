using Test, Bitcoin, ECC, Sockets

tests = ["network", "block", "address", "op", "script", "helper", "tx", "node"]

for t ∈ tests
  include("$(t)test.jl")
end
