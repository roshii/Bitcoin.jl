using Test, Bitcoin, ECC, Sockets

tests = ["network", "block", "node", "address", "op", "script", "helper", "tx"]

for t ∈ tests
  include("$(t)test.jl")
end
