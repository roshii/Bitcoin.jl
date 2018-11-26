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

    @testset "Elliptic Curve Point Operations" begin
        @testset "Integer Type" begin
            @testset "Not Equal" begin
                a = Point(3, -7, 5, 7)
                b = Point(18, 77, 5, 7)
                @test a != b
                @test !(a != a)
            end
            @testset "On Curve?" begin
                @test_throws DomainError Point(-2, 4, 5, 7)
                @test typeof(Point(3, -7, 5, 7)) <: Point
                @test typeof(Point(18, 77, 5, 7)) <: Point
            end
            @testset "Addition" begin
                @testset "Base Case" begin
                    a = Point(∞, ∞, 5, 7)
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
        end;

        @testset "FiniteElement Type" begin
            @testset "On curve?" begin
                𝑝 = 223
                𝑎, 𝑏 = FieldElement(0, 𝑝), FieldElement(7, 𝑝)

                valid_points = ((192, 105), (17, 56), (1, 193))
                invalid_points = ((200, 119), (42, 99))

                for 𝑃 ∈ valid_points
                    𝑥 = FieldElement(𝑃[1], 𝑝)
                    𝑦 = FieldElement(𝑃[2], 𝑝)
                    @test typeof(Point(𝑥, 𝑦, 𝑎, 𝑏)) <: Point
                end

                for 𝑃 ∈ invalid_points
                    𝑥 = FieldElement(𝑃[1], 𝑝)
                    𝑦 = FieldElement(𝑃[2], 𝑝)
                    @test_throws DomainError Point(𝑥, 𝑦, 𝑎, 𝑏)
                end
            end
            @testset "Addition" begin
                𝑝 = 223
                𝑎 = FieldElement(0, 𝑝)
                𝑏 = FieldElement(7, 𝑝)

                additions = (
                    (192, 105, 17, 56, 170, 142),
                    (47, 71, 117, 141, 60, 139),
                    (143, 98, 76, 66, 47, 71),
                    )

                for 𝑛 ∈ additions
                    𝑃 = Point(FieldElement(𝑛[1],𝑝),FieldElement(𝑛[2],𝑝),𝑎,𝑏)
                    𝑄 = Point(FieldElement(𝑛[3],𝑝),FieldElement(𝑛[4],𝑝),𝑎,𝑏)
                    𝑅 = Point(FieldElement(𝑛[5],𝑝),FieldElement(𝑛[6],𝑝),𝑎,𝑏)
                    @test 𝑃 + 𝑄 == 𝑅
                end
            end
            @testset "Scalar Multiplication" begin
                𝑝 = 223
                𝑎 = FieldElement(0, 𝑝)
                𝑏 = FieldElement(7, 𝑝)

                multiplications = (
                    (2, 192, 105, 49, 71),
                    (2, 143, 98, 64, 168),
                    (2, 47, 71, 36, 111),
                    (4, 47, 71, 194, 51),
                    (8, 47, 71, 116, 55),
                    (21, 47, 71, ∞, ∞)
                    )

                for 𝑛 ∈ multiplications
                    λ = 𝑛[1]
                    i = 2
                    fieldelements = []
                    while i < 6
                        if 𝑛[i] == ∞
                            push!(fieldelements, ∞)
                        else
                            push!(fieldelements, FieldElement(𝑛[i],𝑝))
                        end
                        i += 1
                    end
                    𝑃 = Point(fieldelements[1],fieldelements[2],𝑎,𝑏)
                    𝑅 = Point(fieldelements[3],fieldelements[4],𝑎,𝑏)
                    @test λ * 𝑃 == 𝑅
                end
            end
        end;
    end

    @testset "S256Test" begin

        @testset "Order" begin
            point = N * G
            @test typeof(point) == S256Point{Infinity}
        end

        @testset "Public Point" begin
            points = (
                # secret, x, y
                (7, big"0x5cbdf0646e5db4eaa398f365f2ea7a0e3d419b7e0330e39ce92bddedcac4f9bc", big"0x6aebca40ba255960a3178d6d861a54dba813d0b813fde7b5a5082628087264da"),
                (1485, big"0xc982196a7466fbbbb0e27a940b6af926c1a74d5ad07128c82824a11b5398afda", big"0x7a91f9eae64438afb9ce6448a1c133db2d8fb9254e4546b6f001637d50901f55"),
                (big(2)^128, big"0x8f68b9d2f63b5f339239c1ad981f162ee88c5678723ea3351b7b444c9ec4c0da", big"0x662a9f2dba063986de1d90c2b6be215dbbea2cfe95510bfdf23cbf79501fff82"),
                (big(2)^240 + 2^31, big"0x9577ff57c8234558f293df502ca4f09cbc65a6572c842b39b366f21717945116", big"0x10b49c67fa9365ad7b90dab070be339a1daf9052373ec30ffae4f72d5e66d053"),
            )

            for n ∈ points
                point = S256Point(n[2], n[3])
                @test n[1] * G == point
            end
        end

        @testset "sec" begin
            coefficient = 999^3
            uncompressed = "049d5ca49670cbe4c3bfa84c96a8c87df086c6ea6a24ba6b809c9de234496808d56fa15cc7f3d38cda98dee2419f415b7513dde1301f8643cd9245aea7f3f911f9"
            compressed = "039d5ca49670cbe4c3bfa84c96a8c87df086c6ea6a24ba6b809c9de234496808d5"
            point = coefficient * G
            @test secpubkey(point,false) == hex2bytes(uncompressed)
            @test secpubkey(point,true) == hex2bytes(compressed)
            coefficient = 123
            uncompressed = "04a598a8030da6d86c6bc7f2f5144ea549d28211ea58faa70ebf4c1e665c1fe9b5204b5d6f84822c307e4b4a7140737aec23fc63b65b35f86a10026dbd2d864e6b"
            compressed = "03a598a8030da6d86c6bc7f2f5144ea549d28211ea58faa70ebf4c1e665c1fe9b5"
            point = coefficient * G
            @test secpubkey(point,false) == hex2bytes(uncompressed)
            @test secpubkey(point,true) == hex2bytes(compressed)
            coefficient = 42424242
            uncompressed = "04aee2e7d843f7430097859e2bc603abcc3274ff8169c1a469fee0f20614066f8e21ec53f40efac47ac1c5211b2123527e0e9b57ede790c4da1e72c91fb7da54a3"
            compressed = "03aee2e7d843f7430097859e2bc603abcc3274ff8169c1a469fee0f20614066f8e"
            point = coefficient * G
            @test secpubkey(point,false) == hex2bytes(uncompressed)
            @test secpubkey(point,true) == hex2bytes(compressed)
        end

        @testset "address" begin
            secret = 888^3
            mainnet_address = "148dY81A9BmdpMhvYEVznrM45kWN32vSCN"
            testnet_address = "mieaqB68xDCtbUBYFoUNcmZNwk74xcBfTP"
            point = secret * G
            @test address(point, true, false) == mainnet_address
            @test address(point, true, true) == testnet_address
            secret = 321
            mainnet_address = "1S6g2xBJSED7Qr9CYZib5f4PYVhHZiVfj"
            testnet_address = "mfx3y63A7TfTtXKkv7Y6QzsPFY6QCBCXiP"
            point = secret * G
            @test address(point, false, false) == mainnet_address
            @test address(point, false, true) == testnet_address
            secret = 4242424242
            mainnet_address = "1226JSptcStqn4Yq9aAmNXdwdc2ixuH9nb"
            testnet_address = "mgY3bVusRUL6ZB2Ss999CSrGVbdRwVpM8s"
            point = secret * G
            @test address(point, false, false) == mainnet_address
            @test address(point, false, true) == testnet_address
        end

        @testset "verify" begin
            point = S256Point(
                big"0x887387e452b8eacc4acfde10d9aaf7f6d9a0f975aabb10d006e4da568744d06c",
                big"0x61de6d95231cd89026e286df3b6ae4a894a3378e393e93a0f45b666329a0ae34")
            z = big"0xec208baa0fc1c19f708a9ca96fdeff3ac3f230bb4a7ba4aede4942ad003c0f60"
            r = big"0xac8d1c87e51d0d441be8b3dd5b05c8795b48875dffe00b7ffcfac23010d3a395"
            s = big"0x68342ceff8935ededd102dd876ffd6ba72d6a427a3edb13d26eb0781cb423c4"
            @test verify(point, z, Signature(r, s))
            z = big"0x7c076ff316692a3d7eb3c3bb0f8b1488cf72e1afcd929e29307032997a838a3d"
            r = big"0xeff69ef2b1bd93a66ed5219add4fb51e11a840f404876325a1e8ffe0529a2c"
            s = big"0xc7207fee197d27c618aea621406f6bf5ef6fca38681d82b2f06fddbdce6feab6"
            @test verify(point, z, Signature(r, s))
        end
    end

    @testset "Private Key Test" begin
        pk = PrivateKey(rand(big.(0:big(2)^256)))
        𝑧 = rand(big.(0:big(2)^256))
        𝑠 = pksign(pk, 𝑧)
        @test verify(pk.𝑃, 𝑧, 𝑠)
    end
end
