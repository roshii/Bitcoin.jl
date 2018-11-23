"""
    This file is part of bitcoin.jl

    bitcoin.jl is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    bitcoin.jl is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with bitcoin.jl.  If not, see <https://www.gnu.org/licenses/>.
"""

primitive type Infinity <: Number 8 end

Infinity(x::Real) = x<0 ? reinterpret(Infinity, Int8(-1)) : x>0 ? reinterpret(Infinity, Int8(1)) : throw(DomainError("Value must not be 0"))

function show(io::IO, z::Infinity)
    if z == Infinity(1)
        inf = "∞"
    else
        inf = "-∞"
    end
    print(io, inf)
end

const ∞ = Infinity(1)

#promote_rule(::Type{Real}, ::Type{Infinity}) = Infinity
# promote_rule(::Infinity, x::Real) where {T<:Real} = Infinity(x)

+(x::Infinity) = x
-(x::Infinity) = x == ∞ ? Infinity(-1) : ∞
inv(x::Infinity) = x

Finite = Union{Integer,PrimeField}

==(::Infinity,::Finite) = false
==(::Finite,::Infinity) = false

+(x::Infinity,::Integer...) = x
-(x::Infinity,::Integer...) = x
+(x::Infinity,y::Infinity) = x == y ? x : NaN
*(n::Signed,x::Infinity) = n == 0 ? 0 : n < 0 ? -x : x
^(x::Infinity,n::Integer) = x
