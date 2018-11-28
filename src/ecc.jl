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

import Base.+, Base.-, Base.*, Base.^, Base./, Base.inv, Base.==
import Base.show
export FieldElement, Point, S256Element, S256Point, Infinity, Signature, PrivateKey
export int2bytes, bytes2int, encodebase58checksum, encodebase58
export infield, iselliptic, secpubkey, address, verify, pksign, sig2der, der2sig
export +, -, *, ^, /, ==, show
export ∞, G, N

include("helper.jl")

abstract type PrimeField <: Number end

infield(x::Number,y::Number) = x >= 0 && x < y

# Declare FieldElement type in which 𝑛 ∈ 𝐹𝑝 and 𝑝 ∈ ℙ
struct FieldElement <: PrimeField
    𝑛::Integer
    𝑝::Integer
    FieldElement(𝑛,𝑝) = !infield(𝑛,𝑝) ? throw(DomainError("𝑛 is not in field range")) : new(𝑛,𝑝)
end

# Formats PrimeField as 𝑛 : 𝐹ₚ
function show(io::IO, z::PrimeField)
    print(io, z.𝑛, " : 𝐹", z.𝑝)
end

# Returns true if both 𝑛 and 𝑝 are the same
==(𝑋₁::PrimeField,𝑋₂::PrimeField) = 𝑋₁.𝑝 == 𝑋₂.𝑝 && 𝑋₁.𝑛 == 𝑋₂.𝑛
==(::PrimeField,::Integer) = false


# Adds two numbers of the same field
function +(𝑋₁::PrimeField,𝑋₂::PrimeField)
    if 𝑋₁.𝑝 != 𝑋₂.𝑝
        throw(DomainError("Cannot operate on two numbers in different Fields"))
    else
        𝑛 = mod(𝑋₁.𝑛 + 𝑋₂.𝑛, 𝑋₁.𝑝)
        return typeof(𝑋₁)(𝑛, 𝑋₁.𝑝)
    end
end

# Substracts two numbers of the same field
function -(𝑋₁::PrimeField,𝑋₂::PrimeField)
    if 𝑋₁.𝑝 != 𝑋₂.𝑝
        throw(DomainError("Cannot operate on two numbers in different Fields"))
    else
        𝑛 = mod(𝑋₁.𝑛 - 𝑋₂.𝑛, 𝑋₁.𝑝)
        return typeof(𝑋₁)(𝑛, 𝑋₁.𝑝)
    end
end

# Multiplies two numbers of the same field
function *(𝑋₁::PrimeField,𝑋₂::PrimeField)
    if 𝑋₁.𝑝 != 𝑋₂.𝑝
        throw(DomainError("Cannot operate on two numbers in different Fields"))
    else
        𝑛 = mod(𝑋₁.𝑛 * 𝑋₂.𝑛, 𝑋₁.𝑝)
        return typeof(𝑋₁)(𝑛, 𝑋₁.𝑝)
    end
end

# Multiplies a PrimeField by an Integer
function *(𝑐::Integer,𝑋::PrimeField)
    𝑛 = mod(𝑐 * 𝑋.𝑛, 𝑋.𝑝)
    return typeof(𝑋)(𝑛, 𝑋.𝑝)
end

# Returns 𝑋ᵏ where using Fermat's Little Theorem
function ^(𝑋::PrimeField,𝑘::Int)
    𝑛 = powermod(𝑋.𝑛, mod(𝑘, (𝑋.𝑝 - 1)), 𝑋.𝑝)
    return typeof(𝑋)(𝑛, 𝑋.𝑝)
end

# Returns 1/𝑋 as a special case of exponentiation where 𝑘 = -1
function inv(𝑋::PrimeField)
    𝑛 = powermod(𝑋.𝑛, mod(-1, (𝑋.𝑝 - 1)), 𝑋.𝑝)
    return typeof(𝑋)(𝑛, 𝑋.𝑝)
end

# Returns 𝑋₁/𝑋₂ using Fermat's Little Theorem
function /(𝑋₁::PrimeField,𝑋₂::PrimeField)
    if 𝑋₁.𝑝 != 𝑋₂.𝑝
        throw(DomainError("Cannot operate on two numbers in different Fields"))
    else
        𝑛 = mod(𝑋₁.𝑛 * powermod(𝑋₂.𝑛, 𝑋₁.𝑝 - 2, 𝑋₁.𝑝), 𝑋₁.𝑝)
        return typeof(𝑋₁)(𝑛, 𝑋₁.𝑝)
    end
end

include("infinity.jl")

abstract type AbstractPoint end

function iselliptic(𝑥::Number,𝑦::Number,𝑎::Number,𝑏::Number)
    𝑦^2 == 𝑥^3 + 𝑎*𝑥 + 𝑏
end

POINTTYPES = Union{Integer,PrimeField}

# Represents a point with coordinates (𝑥,𝑦) on an elliptic curve where 𝑦² = 𝑥³ + 𝑎𝑥 + 𝑏
# Optional parameter 𝑝 represents finite field 𝐹ₚ and will convert all other parameter to PrimeField
# Point(∞,∞,𝑎,𝑏) represents point at infinity
# Returns an error if elliptic curve equation isn't satisfied
struct Point{T<:Number,S<:Number} <: AbstractPoint
    𝑥::T
    𝑦::T
    𝑎::S
    𝑏::S
    Point{T,S}(𝑥,𝑦,𝑎,𝑏) where {T<:Number,S<:Number} = new(𝑥,𝑦,𝑎,𝑏)
end

Point(𝑥::Infinity,𝑦::Infinity,𝑎::T,𝑏::T) where {T<:POINTTYPES} = Point{Infinity,T}(𝑥,𝑦,𝑎,𝑏)
Point(𝑥::T,𝑦::T,𝑎::T,𝑏::T) where {T<:POINTTYPES} = !iselliptic(𝑥,𝑦,𝑎,𝑏) ? throw(DomainError("Point is not on curve")) : Point{T,T}(𝑥,𝑦,𝑎,𝑏)
Point(𝑥::Infinity,𝑦::Infinity,𝑎::T,𝑏::T,𝑝::T) where {T<:Integer} = Point(𝑥,𝑦,FieldElement(𝑎,𝑝),FieldElement(𝑏,𝑝))
Point(𝑥::T,𝑦::T,𝑎::T,𝑏::T,𝑝::T) where {T<:Integer} = Point(FieldElement(𝑥,𝑝),FieldElement(𝑦,𝑝),FieldElement(𝑎,𝑝),FieldElement(𝑏,𝑝))

# Formats AbstractPoint as (𝑥, 𝑦) on 𝑦² = 𝑥³ + 𝑎𝑥 + 𝑏 (: 𝐹ₚ)
function show(io::IO, z::AbstractPoint)
    if typeof(z.𝑥) <: PrimeField
        x, y = z.𝑥.𝑛, z.𝑦.𝑛
    else
        x, y = z.𝑥, z.𝑦
    end

    if typeof(z.𝑎) <: PrimeField
        a, b = z.𝑎.𝑛, z.𝑏.𝑛
        field = string(" : 𝐹", z.𝑎.𝑝)
    else
        a, b = z.𝑎, z.𝑏
        field = ""
    end
    print(io, "(", x, ", ", y, ") on 𝑦² = 𝑥³ + ", a, "𝑥 + ", b, field)
end

# Returns the point resulting from the intersection of the curve and the
# straight line defined by the points P and Q
function +(𝑃::AbstractPoint,𝑄::AbstractPoint)
    T = typeof(𝑃)
    S = typeof(𝑃.𝑎)
    if 𝑃.𝑎 != 𝑄.𝑎 || 𝑃.𝑏 != 𝑄.𝑏
        throw(DomainError("Points are not on the same curve"))

    # Case 0
    elseif 𝑃.𝑥 == ∞
        return 𝑄
    elseif 𝑄.𝑥 == ∞
        return 𝑃
    elseif 𝑃.𝑥 == 𝑄.𝑥 && 𝑃.𝑦 != 𝑄.𝑦
        # something more elegant should exist to return correct point type
        if T <: Point
            return Point{Infinity,S}(∞, ∞, 𝑃.𝑎, 𝑃.𝑏)
        elseif T <: S256Point
            return S256Point{Infinity}(∞, ∞, 𝑃.𝑎, 𝑃.𝑏)
        end

    # Case 1
    elseif 𝑃.𝑥 != 𝑄.𝑥
        λ = (𝑄.𝑦 - 𝑃.𝑦) / (𝑄.𝑥 - 𝑃.𝑥)
        𝑥 = λ^2 - 𝑃.𝑥 - 𝑄.𝑥
    # Case 2
    else
        λ = (3 * 𝑃.𝑥^2 + 𝑃.𝑎) / (2 * 𝑃.𝑦)
        𝑥 = λ^2 - 2 * 𝑃.𝑥
    end
    𝑦 = λ * (𝑃.𝑥 - 𝑥) - 𝑃.𝑦
    return T(S(𝑥), S(𝑦), 𝑃.𝑎, 𝑃.𝑏)
end

# Scalar multiplication of a Point
function *(λ::Integer,𝑃::Point)
    𝑅 = Point(∞, ∞, 𝑃.𝑎, 𝑃.𝑏)
    while λ > 0
        𝑅 += 𝑃
        λ -= 1
    end
    return 𝑅
end


struct Signature
    𝑟::BigInt
    𝑠::BigInt
    Signature(𝑟, 𝑠) = new(𝑟, 𝑠)
end

# Formats Signature as (r, s) in hexadecimal format
function show(io::IO, z::Signature)
    print(io, "scep256k1 signature(𝑟, 𝑠):\n", string(z.𝑟, base = 16), ",\n", string(z.𝑠, base = 16))
end

==(x::Signature, y::Signature) = x.𝑟 == y.𝑟 && x.𝑠 == y.𝑠

# Returns a DER signature from a given Signature()
# Investigate: 0x00 was added if high bit is found on r of s in python implementation
# but seem to break der2sig in Julia
function sig2der(x::Signature)
    rbin = int2bytes(x.𝑟)
    # if rbin has a high bit, add a 00
    # if rbin[1] >= 128
    #     rbin = pushfirst!(rbin, 0x00)
    # end
    result = cat([0x02], int2bytes(length(rbin)), rbin; dims=1)
    sbin = int2bytes(x.𝑠)
    # if sbin has a high bit, add a 00
    # if sbin[1] >= 128
    #     sbin = pushfirst!(sbin, 0x00)
    # end
    result = cat(result, [0x02], int2bytes(length(rbin)), sbin; dims=1)
    return cat([0x30], int2bytes(length(result)), result; dims=1)
end

# Returns a Signature() for a given signature in DER format
function der2sig(signature_bin::AbstractArray{UInt8})
    s = IOBuffer(signature_bin)
    bytes = UInt8[]
    readbytes!(s, bytes, 1)
    if bytes[1] != 0x30
        throw(DomainError("Bad Signature"))
    end
    readbytes!(s, bytes, 1)
    if bytes[1] + 2 != length(signature_bin)
        throw(DomainError("Bad Signature Length"))
    end
    readbytes!(s, bytes, 1)
    if bytes[1] != 0x02
        throw(DomainError("Bad Signature"))
    end
    readbytes!(s, bytes, 1)
    rlength = Int(bytes[1])
    readbytes!(s, bytes, rlength)
    r = bytes2hex(bytes)
    readbytes!(s, bytes, 1)
    if bytes[1] != 0x02
        throw(DomainError("Bad Signature"))
    end
    readbytes!(s, bytes, 1)
    slength = Int(bytes[1])
    readbytes!(s, bytes, slength)
    s = bytes2hex(bytes)
    if length(signature_bin) != 6 + rlength + slength
        throw(DomainError("Signature too long"))
    end
    return Signature(parse(BigInt, r, base=16),
                     parse(BigInt, s, base=16))
end


# scep256k1 constants
A = 0
B = 7
P = big(2)^256 - 2^32 - 977
N = big"0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141"

# scep256k1 field
struct S256Element <: PrimeField
     𝑛::BigInt
     𝑝::BigInt
     S256Element(𝑛,𝑝=P) = !infield(𝑛,𝑝) ? throw(DomainError("𝑛 is not in field range")) : new(𝑛,𝑝)
end

S256Element(x::S256Element) = x

# S256Element(n::Integer) = S256Element(big(n))

# Formats S256Element showing 𝑛 in hexadecimal format
function show(io::IO, z::S256Element)
    print(io, string(z.𝑛, base = 16),"\n(in scep256k1 field)")
end

A = S256Element(A)
B = S256Element(B)

# scep256k1 Point
struct S256Point{T<:Number} <: AbstractPoint
    𝑥::T
    𝑦::T
    𝑎::S256Element
    𝑏::S256Element
    S256Point{T}(𝑥,𝑦,𝑎=A,𝑏=B) where {T<:Number} = new(𝑥,𝑦,𝑎,𝑏)
end

S256Point(::Infinity,::Infinity) = S256Point{Infinity}(∞,∞)
S256Point(𝑥::S256Element,𝑦::S256Element) = !iselliptic(𝑥,𝑦,A,B) ? throw(DomainError("Point is not on curve")) : S256Point{S256Element}(𝑥,𝑦)
S256Point(x::BigInt,y::BigInt) = S256Point{S256Element}(S256Element(x),S256Element(y))

# Formats S256Point as (𝑥, 𝑦) in hexadecimal format
function show(io::IO, z::S256Point)
    if typeof(z.𝑥) <: PrimeField
        x, y = z.𝑥.𝑛, z.𝑦.𝑛
    else
        x, y = z.𝑥, z.𝑦
    end
    print(io, "scep256k1 Point(𝑥,𝑦):\n", string(x, base = 16), ",\n", string(y, base = 16))
end

# Compares two S256Point, returns true if coordinates are equal
==(x::S256Point, y::S256Point) = x.𝑥 == y.𝑥 && x.𝑦 == y.𝑦

# Scalar multiplication of an S256Point
function *(λ::Integer,𝑃::S256Point)
    𝑅 = S256Point(∞, ∞)
    λ =  mod(λ, N)
    while λ > 0
        if λ & 1 != 0
            𝑅 += 𝑃
        end
        𝑃 += 𝑃
        λ >>= 1
    end
    return 𝑅
end

# Returns the binary version of the SEC public key
function secpubkey(P::T, compressed::Bool=true) where {T<:S256Point}
    if compressed
        if mod(P.𝑦.𝑛, 2) == 0
            indice = 0x02
        else
            indice = 0x03
        end
        return cat(indice,hex2bytes(string(P.𝑥.𝑛, base=16));dims=1)
    else
        return cat(0x04,hex2bytes(string(P.𝑥.𝑛, base=16)),hex2bytes(string(P.𝑦.𝑛, base=16));dims=1)
    end
end

# Returns the Base58 public address
function address(P::T, compressed::Bool=true, testnet::Bool=false) where {T<:S256Point}
    s = secpubkey(P, compressed)
    h160 = ripemd160(sha256(s))
    if testnet
        prefix = 0x6f
    else
        prefix = 0x00
    end
    result = pushfirst!(h160, prefix)
    return encodebase58checksum(result)
end


# Returns true if sig is a valid signature for z given public key pub, false if not
function verify(𝑃::AbstractPoint,𝑧::Integer,sig::Signature)
    𝑠⁻¹ = powermod(sig.𝑠, N - 2, N)
    𝑢 = mod(𝑧 * 𝑠⁻¹, N)
    𝑣 = mod(sig.𝑟 * 𝑠⁻¹, N)
    𝑅 = 𝑢 * G + 𝑣 * 𝑃
    return 𝑅.𝑥.𝑛 == sig.𝑟
end

G = S256Point(big"0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
              big"0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")


struct PrivateKey
    𝑒::Integer
    𝑃::AbstractPoint
    PrivateKey(𝑒) = new(𝑒, 𝑒 * G)
end

# Returns a Signature for a given PrivateKey pk and data 𝑧
function pksign(pk::PrivateKey, 𝑧::Integer)
    𝑘 = rand(big.(0:N))
    𝑟 = (𝑘 * G).𝑥.𝑛
    𝑘⁻¹ = powermod(𝑘, N - 2, N)
    𝑠 = mod((𝑧 + 𝑟 * pk.𝑒) * 𝑘⁻¹, N)
    if 𝑠 > N / 2
        𝑠 = N - 𝑠
    end
    return Signature(𝑟, 𝑠)
end
