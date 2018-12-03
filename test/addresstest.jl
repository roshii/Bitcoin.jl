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

@testset "address" begin
  # G = S256Point(big"0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
  #     big"0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")
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
