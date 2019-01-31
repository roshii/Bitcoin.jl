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

@testset "Helper" begin
    @testset "read_varint" begin
        tests = [([0x01], 1),
                 ([0xfd, 0xd0, 0x24], 9424),
                 ([0xfe, 0x30, 0x33, 0xff, 0xb3], -1275120848),
                 ([0xff, 0x70, 0x9a, 0xeb, 0xb4, 0xbb, 0x7f, 0x00, 0x00], 140444170951280)]
        for t in tests
            @test Bitcoin.read_varint(IOBuffer(t[1])) == t[2]
        end
    end
    @testset "encode_varint" begin
        want = [0xfd, 0xfe, 0x00]
        @test Bitcoin.encode_varint(254) == want
    end
end
