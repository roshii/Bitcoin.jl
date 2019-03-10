using Test, Bitcoin, ECC

tests = ["network", "block", "address", "op", "script", "helper", "tx"]

for t ∈ tests
  include("$(t)test.jl")
end
