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

@testset "Bitcoin address functions" begin
        @testset "address" begin
                secret = 888^3
                mainnet_address = "148dY81A9BmdpMhvYEVznrM45kWN32vSCN"
                testnet_address = "mieaqB68xDCtbUBYFoUNcmZNwk74xcBfTP"
                point = secret * ECC.G
                @test address(point, true, false) == mainnet_address
                @test address(point, true, true) == testnet_address
                secret = 321
                mainnet_address = "1S6g2xBJSED7Qr9CYZib5f4PYVhHZiVfj"
                testnet_address = "mfx3y63A7TfTtXKkv7Y6QzsPFY6QCBCXiP"
                point = secret * ECC.G
                @test address(point, false, false) == mainnet_address
                @test address(point, false, true) == testnet_address
                secret = 4242424242
                mainnet_address = "1226JSptcStqn4Yq9aAmNXdwdc2ixuH9nb"
                testnet_address = "mgY3bVusRUL6ZB2Ss999CSrGVbdRwVpM8s"
                point = secret * ECC.G
                @test address(point, false, false) == mainnet_address
                @test address(point, false, true) == testnet_address
        end
        @testset "WIF" begin
                pk = PrivateKey(big(2)^256-big(2)^199)
                expected = "L5oLkpV3aqBJ4BgssVAsax1iRa77G5CVYnv9adQ6Z87te7TyUdSC"
                @test wif(pk, true, false) == expected
                pk = PrivateKey(big(2)^256-big(2)^201)
                expected = "93XfLeifX7Jx7n7ELGMAf1SUR6f9kgQs8Xke8WStMwUtrDucMzn"
                @test wif(pk, false, true) == expected
                pk = PrivateKey(parse(BigInt, "0dba685b4511dbd3d368e5c4358a1277de9486447af7b3604a69b8d9d8b7889d", base=16))
                expected = "5HvLFPDVgFZRK9cd4C5jcWki5Skz6fmKqi1GQJf5ZoMofid2Dty"
                @test wif(pk, false, false) == expected
                pk = PrivateKey(parse(BigInt, "1cca23de92fd1862fb5b76e5f4f50eb082165e5191e116c18ed1a6b24be6a53f", base=16))
                expected = "cNYfWuhDpbNM1JWc3c6JTrtrFVxU4AGhUKgw5f93NP2QaBqmxKkg"
                @test wif(pk, true, true) == expected
        end
end
