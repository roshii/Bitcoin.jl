"""
    This file is part of Bitcoin.jl

    Bitcoin.jl is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    Bitcoin.jl is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Bitcoin.jl.  If not, see <https://www.gnu.org/licenses/>.
"""

using Test, Bitcoin

tests = ["infinitytest", "helpertest", "ecctest"]

for t ∈ tests
  include("$(t).jl")
end

# 19ZewH8Kk1PDbSNdJ97FP4EiCjTRcJtV7o
# 19ZewH8Kk1PDbSNdJ97FP4EiCjTRaZMZQA
