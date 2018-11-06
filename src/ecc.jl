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

import Base.+, Base.-, Base.*, Base.^, Base./, Base.inv
export FieldElement, Point
export +, -, *, ^, /

# Initialize FieldElement in which 𝑛 ∈ 𝐹𝑝
struct FieldElement
    𝑛::Integer
    𝑝::Integer
    FieldElement(𝑛,𝑝) = 𝑛 < 0 || 𝑛 >= 𝑝 ? throw(DomainError("𝑛 is not in field range")) : new(𝑛,𝑝)
end

# Adds two numbers of the same field
function +(𝑥₁::FieldElement,𝑥₂::FieldElement)
    if 𝑥₁.𝑝 != 𝑥₂.𝑝
        throw(DomainError("Cannot operate on two numbers in different Fields"))
    else
        𝑛 = mod(𝑥₁.𝑛 + 𝑥₂.𝑛, 𝑥₁.𝑝)
        return FieldElement(𝑛, 𝑥₁.𝑝)
    end
end

# Substracts two numbers of the same field
function -(𝑥₁::FieldElement,𝑥₂::FieldElement)
    if 𝑥₁.𝑝 != 𝑥₂.𝑝
        throw(DomainError("Cannot operate on two numbers in different Fields"))
    else
        𝑛 = mod(𝑥₁.𝑛 - 𝑥₂.𝑛, 𝑥₁.𝑝)
        return FieldElement(𝑛, 𝑥₁.𝑝)
    end
end

# Multiplies two numbers of the same field
function *(𝑥₁::FieldElement,𝑥₂::FieldElement)
    if 𝑥₁.𝑝 != 𝑥₂.𝑝
        throw(DomainError("Cannot operate on two numbers in different Fields"))
    else
        𝑛 = mod(𝑥₁.𝑛 * 𝑥₂.𝑛, 𝑥₁.𝑝)
        return FieldElement(𝑛, 𝑥₁.𝑝)
    end
end

# Returns 𝑥ᵏ modulo 𝑝 by iterating over 𝑘 where 𝑥, 𝑝, 𝑘 ∈ Integer
function pow(𝑥::Int,𝑘::Int,𝑝::Int)
    result = 1
    while 𝑘 > 0
        result = mod(result *= 𝑥, 𝑝)
        𝑘 -= 1
    end
    return result
end

# Returns 𝑥ᵏ where using Fermat's Little Theorem
function ^(𝑥::FieldElement,𝑘::Int)
    𝑛 = pow(𝑥.𝑛, mod(𝑘, (𝑥.𝑝 - 1)), 𝑥.𝑝)
    return FieldElement(𝑛, 𝑥.𝑝)
end

# Returns 1/𝑥 as a special case of exponentiation where 𝑘 = -1
function inv(𝑥::FieldElement)
    𝑛 = pow(𝑥.𝑛, mod(-1, (𝑥.𝑝 - 1)), 𝑥.𝑝)
    return FieldElement(𝑛, 𝑥.𝑝)
end

# Returns 𝑥₁/𝑥₂ using Fermat's Little Theorem
function /(𝑥₁::FieldElement,𝑥₂::FieldElement)
    if 𝑥₁.𝑝 != 𝑥₂.𝑝
        throw(DomainError("Cannot operate on two numbers in different Fields"))
    else
        𝑛 = mod(𝑥₁.𝑛 * pow(𝑥₂.𝑛, 𝑥₁.𝑝 - 2, 𝑥₁.𝑝), 𝑥₁.𝑝)
        return FieldElement(𝑛, 𝑥₁.𝑝)
    end
end

ℤ = Union{Nothing,Integer}

# Represents a point with coordinates (𝑥,𝑦) on an elliptic curve where 𝑦² = 𝑥³ + 𝑎𝑥 + 𝑏
# Point(nothing,nothing,𝑎,𝑏) represents point at infinity
# Returns an error if elliptic curve equation isn't satisfied
struct Point
   𝑥::ℤ
   𝑦::ℤ
   𝑎::Integer
   𝑏::Integer
   Point(𝑥::Nothing,𝑦::Nothing,𝑎,𝑏) = new(𝑥,𝑦,𝑎,𝑏)
   Point(𝑥,𝑦,𝑎,𝑏) = 𝑦^2 != 𝑥^3 + 𝑎*𝑥 + 𝑏 ? throw(DomainError("Point is not on curve")) : new(𝑥,𝑦,𝑎,𝑏)
end

# Returns the point resulting from the intersection of the curve and the
# straight line defined by the points P and Q
function +(𝑃::Point,𝑄::Point)
    if 𝑃.𝑎 != 𝑄.𝑎 || 𝑃.𝑏 != 𝑄.𝑏
        throw(DomainError("Points are not on the same curve"))
    elseif 𝑃.𝑥 == nothing
        return 𝑄
    elseif 𝑄.𝑥 == nothing
        return 𝑃
    elseif 𝑃.𝑥 == 𝑄.𝑥 && 𝑃.𝑦 != 𝑄.𝑦
        return Point(nothing, nothing, 𝑃.𝑎, 𝑃.𝑏)
    elseif 𝑃.𝑥 != 𝑄.𝑥
        λ = (𝑄.𝑦 - 𝑃.𝑦) / (𝑄.𝑥 - 𝑃.𝑥)
        𝑥 = λ^2 - 𝑃.𝑥 - 𝑄.𝑥
        𝑦 = λ * (𝑃.𝑥 - 𝑥) - 𝑃.𝑦
        return Point(𝑥, 𝑦, 𝑃.𝑎, 𝑃.𝑏)
    else
        λ = (3 * 𝑃.𝑥^2 + 𝑃.𝑎) / (2 * 𝑃.𝑦)
        𝑥 = λ^2 - 2 * 𝑃.𝑥
        𝑦 = λ * (𝑃.𝑥 - 𝑥) - 𝑃.𝑦
        return Point(𝑥, 𝑦, 𝑃.𝑎, 𝑃.𝑏)
    end
end
