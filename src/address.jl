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

export address

include("base58.jl")

# Returns the Base58 public address
function address(P::T, compressed::Bool=true, testnet::Bool=false) where {T<:S256Point}
    s = point2sec(P, compressed)
    h160 = ripemd160(sha256(s))
    if testnet
        prefix = 0x6f
    else
        prefix = 0x00
    end
    result = pushfirst!(h160, prefix)
    return encodebase58checksum(result)
end
