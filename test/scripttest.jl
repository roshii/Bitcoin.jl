"""
    Copyright (C) 2018-2019 Simon Castano

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
    along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
"""

@testset "Script" begin
    @testset "parse" begin
        script_pubkey = IOBuffer(hex2bytes("6a47304402207899531a52d59a6de200179928ca900254a36b8dff8bb75f5f5d71b1cdc26125022008b422690b8461cb52c3cc30330b23d574351872b7c361e9aae3649071c1a7160121035d5c93d9ac96881f19ba1f686f15f009ded7c62efe85a872e6a19b43c15a2937"))
        script = Bitcoin.scriptparse(script_pubkey)
        want = hex2bytes("304402207899531a52d59a6de200179928ca900254a36b8dff8bb75f5f5d71b1cdc26125022008b422690b8461cb52c3cc30330b23d574351872b7c361e9aae3649071c1a71601")
        @test script.instructions[1] == want
        want = hex2bytes("035d5c93d9ac96881f19ba1f686f15f009ded7c62efe85a872e6a19b43c15a2937")
        @test script.instructions[2] == want
    end
    @testset "Serialize" begin
        want = "6a47304402207899531a52d59a6de200179928ca900254a36b8dff8bb75f5f5d71b1cdc26125022008b422690b8461cb52c3cc30330b23d574351872b7c361e9aae3649071c1a7160121035d5c93d9ac96881f19ba1f686f15f009ded7c62efe85a872e6a19b43c15a2937"
        script_pubkey = IOBuffer(hex2bytes(want))
        script = Bitcoin.scriptparse(script_pubkey)
        @test bytes2hex(Bitcoin.scriptserialize(script)) == want
    end
end
