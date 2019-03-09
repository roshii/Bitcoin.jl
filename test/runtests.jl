using Test, Bitcoin, ECC

tests = ["network", "address", "op", "script", "helper", "tx", "block"]

for t ∈ tests
  include("$(t)test.jl")
end
