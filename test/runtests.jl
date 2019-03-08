using Test, Bitcoin, ECC

tests = ["address", "op", "script", "helper", "tx", "block"]

for t ∈ tests
  include("$(t)test.jl")
end
