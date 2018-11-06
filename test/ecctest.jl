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

@testset "ECC Tests" begin
    @testset "Field Element Operations" begin
        @testset "Addition" begin
            a = FieldElement(2, 31)
            b = FieldElement(15, 31)
            @test a+b == FieldElement(17, 31)
            a = FieldElement(17, 31)
            b = FieldElement(21, 31)
            @test a+b == FieldElement(7, 31)
        end
        @testset "Substraction" begin
            a = FieldElement(29, 31)
            b = FieldElement(4, 31)
            @test a-b == FieldElement(25, 31)
            a = FieldElement(15, 31)
            b = FieldElement(30, 31)
            @test a-b == FieldElement(16, 31)
        end
        @testset "Multiplication" begin
            a = FieldElement(24, 31)
            b = FieldElement(19, 31)
            @test a*b == FieldElement(22, 31)
        end
        @testset "Power" begin
            a = FieldElement(17, 31)
            @test a^3 == FieldElement(15, 31)
            a = FieldElement(5, 31)
            b = FieldElement(18, 31)
            @test a^5 * b == FieldElement(16, 31)
        end
        @testset "Division" begin
            a = FieldElement(3, 31)
            b = FieldElement(24, 31)
            @test a/b == FieldElement(4, 31)
            a = FieldElement(17, 31)
            @test a^-3 == FieldElement(29, 31)
            a = FieldElement(4, 31)
            b = FieldElement(11, 31)
            @test a^-4*b == FieldElement(13, 31)
        end
    end;

    @testset "Point Operations" begin

        @testset "Not Equal" begin
            a = Point(3, -7, 5, 7)
            b = Point(18, 77, 5, 7)
            @test a != b
            @test !(a != a)
        end

        @testset "On Curve" begin
            @test_throws DomainError Point(-2, 4, 5, 7)
            @test typeof(Point(3, -7, 5, 7)) == Point
            @test typeof(Point(18, 77, 5, 7)) == Point
        end

        @testset "Addition" begin
            @testset "Base Case" begin
                a = Point(nothing, nothing, 5, 7)
                b = Point(2, 5, 5, 7)
                c = Point(2, -5, 5, 7)
                @test a + b == b
                @test b + a == b
                @test b + c == a
            end

            @testset "Case 1" begin
                a = Point(3, 7, 5, 7)
                b = Point(-1, -1, 5, 7)
                @test a + b == Point(2, -5, 5, 7)
            end

            @testset "Case 2" begin
                a = Point(-1, 1, 5, 7)
                @test a + a == Point(18, -77, 5, 7)
            end
        end
    end
end
