using Test, Bitcoin, ECC

tests = ["address", "op", "script", "helper", "tx"]

for t ∈ tests
  include("$(t)test.jl")
end
