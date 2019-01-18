"""
    Copyright (C) 2019 Simon Castano

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

@testset "Stack Operators" begin
    @testset "encode/decode num" begin
        tests = [([0x75, 0x39, 0xd7, 0xf9], -2044148085),
        ([0x1b, 0x44, 0x8d, 0x17, 0x61, 0x36, 0x45, 0x51, 0x44, 0x38, 0x15, 0x20, 0xeb, 0x3f, 0xd1, 0xbc], -80840166210881125725200074314630382619),
        ([0xd3, 0x2c, 0xd5, 0xb9, 0x8b, 0xfa, 0x37, 0xd5, 0x24, 0xd0, 0xd2, 0xe8, 0x81, 0x8c, 0xcb, 0x15, 0xe5, 0xfe, 0xdd, 0x95, 0x55, 0xe4, 0x3d, 0x01, 0x82, 0x67, 0xc2, 0x23, 0xc5, 0xd6, 0x0c, 0x90, 0xe9, 0x72, 0xff, 0x9a, 0xd1, 0xcf, 0x16, 0xfa, 0x83], -8494629442587523471751141882831378743107401446683360409874466988135963066279425110931949604908243),
        ([0x7e, 0x5e, 0x14, 0x7b, 0x73, 0x6b, 0x57, 0x64, 0x67, 0x6d, 0x0b, 0x70, 0xa1, 0x6e, 0x71], 588973400481137931526979715425656446),
        ([0x7b], 123)]
        for i in 1:length(tests)
            @test decode_num(tests[i][1]) == tests[i][2]
            @test encode_num(tests[i][2]) == tests[i][1]
        end
    end
    @testset "Push value onto stack" begin
        test_stack = [[0x75, 0x39, 0xd7, 0xf9],
        [0x86, 0x8f, 0xf9, 0x73, 0x0a, 0x3c, 0x0c, 0xb9],
        [0xe2, 0xd6],
        [0x7b],
        [0x92, 0x8b, 0xae, 0xed, 0x1e, 0xfb, 0x04, 0x58],
        [0xdb, 0xaf, 0x44],
        [0x84, 0xd7, 0x35, 0xb7],
        [0xaf, 0x80, 0x91]]
        empty_stack = UInt8[]
        @testset "op_0" begin
            stack = test_stack
            want = stack
            push!(want, UInt8[])
            @test op_0(stack) == true
            @test stack == want
        end
        @testset "op_1negate" begin
            stack = test_stack
            want = stack
            push!(want, [0x81])
            @test op_1negate(stack) == true
            @test stack == want
        end
        @testset "op_2" begin
            stack = test_stack
            want = stack
            push!(want, [0x02])
            @test op_2(stack) == true
            @test stack == want
        end
        @testset "op_3" begin
            stack = test_stack
            want = stack
            push!(want, [0x03])
            @test op_3(stack) == true
            @test stack == want
        end
        @testset "op_4" begin
            stack = test_stack
            want = stack
            push!(want, [0x01])
            @test op_4(stack) == true
            @test stack == want
        end
        @testset "op_5" begin
            stack = test_stack
            want = stack
            push!(want, [0x05])
            @test op_5(stack) == true
            @test stack == want
        end
        @testset "op_6" begin
            stack = test_stack
            want = stack
            push!(want, [0x06])
            @test op_6(stack) == true
            @test stack == want
        end
        @testset "op_7" begin
            stack = test_stack
            want = stack
            push!(want, [0x07])
            @test op_7(stack) == true
            @test stack == want
        end
        @testset "op_8" begin
            stack = test_stack
            want = stack
            push!(want, [0x08])
            @test op_8(stack) == true
            @test stack == want
        end
        @testset "op_9" begin
            stack = test_stack
            want = stack
            push!(want, [0x09])
            @test op_9(stack) == true
            @test stack == want
        end
        @testset "op_10" begin
            stack = test_stack
            want = stack
            push!(want, [0x0a])
            @test op_10(stack) == true
            @test stack == want
        end
        @testset "op_11" begin
            stack = test_stack
            want = stack
            push!(want, [0x0b])
            @test op_11(stack) == true
            @test stack == want
        end
        @testset "op_12" begin
            stack = test_stack
            want = stack
            push!(want, [0x0c])
            @test op_12(stack) == true
            @test stack == want
        end
        @testset "op_13" begin
            stack = test_stack
            want = stack
            push!(want, [0x0d])
            @test op_13(stack) == true
            @test stack == want
        end
        @testset "op_14" begin
            stack = test_stack
            want = stack
            push!(want, [0x0e])
            @test op_14(stack) == true
            @test stack == want
        end
        @testset "op_15" begin
            stack = test_stack
            want = stack
            push!(want, [0x0f])
            @test op_15(stack) == true
            @test stack == want
        end
        @testset "op_16" begin
            stack = test_stack
            want = stack
            push!(want, [0x10])
            @test op_16(stack) == true
            @test stack == want
        end
    end
    @testset "Conditional control flow" begin
        @testset "op_nop" begin
            @test op_nop([UInt8[]]) == true
            @test op_nop([[0x64],
                [0x86, 0x8f, 0xf9, 0x73, 0x0a, 0x3c, 0x0c, 0xb9],
                [0xe2, 0xd6]]) == true
        end
        # TODO review those tests
        @testset "op_if" begin
            want = [[0x64],
                [0x86, 0x8f, 0xf9, 0x73, 0x0a, 0x3c, 0x0c, 0xb9],
                [0xe2, 0xd6]]
            stack = Array{UInt8,1}[]
            items = [0x63,0x0c,0xe2]
            @test op_if(stack,items) == false
            @test stack == []
            @test items == [0x63,0x0c,0xe2]

            stack = want
            @test op_if(stack,items) == false
            @test stack == want
            @test items == UInt8[]

            items == [0x67,0x0d,0x69]
            @test op_if(stack,items) == false
            @test stack == want
            @test items == UInt8[]

            items == [0x63,0x68,0x6b]
            @test op_if(stack,items) == false
            @test stack == want
            @test items == UInt8[]

            items == [0x0d,0x0f,0x7a]
            @test op_if(stack,items) == false
            @test stack == want
            @test items == UInt8[]

            push!(stack,UInt8[])
            items = [0x68,0xc4,0x07]
            @test op_if(stack,items) == true
            @test stack == want
            @test items == [0xc4,0x07]

            items = [0x68,0xc4,0x07]
            @test op_if(stack,items) == true
            pop!(want)
            @test stack == want
            @test items == [0xc4,0x07]
        end
        # TODO create those tests
        @testset "op_notif" begin
        end
        @testset "op_verify" begin
            stack = Array{UInt8,1}[]
            @test op_verify(stack) == false
            @test stack ==  Array{UInt8,1}[]
            stack = [[0x64], [0x86, 0x8f, 0xf9], [0xe2, 0xd6]]
            @test op_verify(stack) == true
            @test stack ==  [[0x64], [0x86, 0x8f, 0xf9]]
            stack = [[0x64], [0x86, 0x8f, 0xf9], [0xe2, 0xd6], UInt8[]]
            @test op_verify(stack) == false
            @test stack ==  [[0x64], [0x86, 0x8f, 0xf9], [0xe2, 0xd6]]
        end
        @testset "op_return" begin
            @test op_return([UInt8[]]) == false
            @test op_return([[0x64],
                [0x86, 0x8f, 0xf9, 0x73, 0x0a, 0x3c, 0x0c, 0xb9],
                [0xe2, 0xd6]]) == false
        end
    end
    @testset "Timelock operations" begin
    end
    @testset "Stack operations" begin
        @testset "op_toaltstack" begin
            stack = Array{UInt8,1}[]
            altstack = stack
            @test op_toaltstack(stack, altstack) == false
            stack = [[0x04], [0x06, 0x0f, 0x09], [0x02, 0x06]]
            altstack = [[0xf4], [0xf6, 0xff, 0xf9], [0xf2, 0xf6]]
            @test op_toaltstack(stack, altstack) == true
            @test stack == [[0x04], [0x06, 0x0f, 0x09]] && altstack == [[0xf4], [0xf6, 0xff, 0xf9], [0xf2, 0xf6], [0x02, 0x06]]
        end
        @testset "op_fromaltstack" begin
            stack = Array{UInt8,1}[]
            altstack = stack
            @test op_toaltstack(stack, altstack) == false
            stack = [[0x04], [0x06, 0x0f, 0x09], [0x02, 0x06]]
            altstack = [[0xf4], [0xf6, 0xff, 0xf9], [0xf2, 0xf6]]
            @test op_fromaltstack(stack, altstack) == true
            @test stack == [[0x04], [0x06, 0x0f, 0x09], [0x02, 0x06],[0xf2, 0xf6]] && altstack == [[0xf4], [0xf6, 0xff, 0xf9]]
        end
        @testset "op_2drop" begin
            stack = [[0x04]]
            @test op_2drop(stack) == false
            stack = [[0x04], [0x06, 0x0f, 0x09], [0x02, 0x06]]
            @test op_2drop(stack) == true
            @test stack == [[0x04]]
        end
        @testset "op_2dup" begin
            stack = [[0x04]]
            @test op_2dup(stack) == false
            stack = [[0x04], [0x06, 0x0f, 0x09], [0x02, 0x06]]
            @test op_2dup(stack) == true
            @test stack == [[0x04], [0x06, 0x0f, 0x09], [0x02, 0x06], [0x06, 0x0f, 0x09], [0x02, 0x06]]
        end
        @testset "op_3dup" begin
            stack = [[0x04], [0x06, 0x0f, 0x09]]
            @test op_3dup(stack) == false
            stack = [[0x04], [0x06, 0x0f, 0x09], [0x02, 0x06]]
            @test op_3dup(stack) == true
            @test stack == [[0x04], [0x06, 0x0f, 0x09], [0x02, 0x06], [0x04], [0x06, 0x0f, 0x09], [0x02, 0x06]]
        end
        @testset "op_2over" begin
            stack = [[0x01], [0x02], [0x03]]
            @test op_2over(stack) == false
            stack = [[0x01], [0x02], [0x03], [0x04], [0x05]]
            @test op_2over(stack) == true
            @test stack == [[0x01], [0x02], [0x03], [0x04], [0x05], [0x02], [0x03]]
        end
        @testset "op_2rot" begin
            stack = [[0x01], [0x02], [0x03], [0x04], [0x05]]
            @test op_2rot(stack) == false
            stack = [[0x01], [0x02], [0x03], [0x04], [0x05], [0x06], [0x07]]
            @test op_2rot(stack) == true
            @test stack == [[0x01], [0x02], [0x03], [0x04], [0x05], [0x06], [0x07], [0x02], [0x03]]
        end
        @testset "op_2swap" begin
            stack = [[0x01], [0x02], [0x03]]
            @test op_2swap(stack) == false
            stack = [[0x01], [0x02], [0x03], [0x04], [0x05]]
            @test op_2swap(stack) == true
            @test stack == [[0x01], [0x04], [0x05], [0x02], [0x03]]
        end
        @testset "op_ifdup" begin
            stack = Array{UInt8,1}[]
            @test op_ifdup(stack) == false
            stack = [[0x01], [0x00]]
            @test op_ifdup(stack) == true
            @test stack == [[0x01], [0x00]]
            stack = [[0x01], [0x02]]
            @test op_ifdup(stack) == true
            @test stack == [[0x01], [0x02], [0x02]]
        end
        @testset "op_depth" begin
            stack = Array{UInt8,1}[]
            @test op_depth(stack) == true
            @test stack == [[]]
            stack = [[0x01], [0x02]]
            @test op_depth(stack) == true
            @test stack == [[0x01], [0x02], [0x02]]
        end
        @testset "op_dup" begin
            stack = Array{UInt8,1}[]
            @test op_dup(stack) == false
            stack = [[0x01], [0x02], [0x03]]
            @test op_dup(stack) == true
            @test stack == [[0x01], [0x02], [0x03], [0x03]]
        end
        @testset "op_nip" begin
            stack = Array{UInt8,1}[[0x01]]
            @test op_nip(stack) == false
            stack = [[0x01], [0x02], [0x03]]
            @test op_nip(stack) == true
            @test stack == [[0x01], [0x03]]
        end
        @testset "op_over" begin
            stack = [[0x01]]
            @test op_over(stack) == false
            stack = [[0x01], [0x02], [0x03], [0x04]]
            @test op_over(stack) == true
            @test stack == [[0x01], [0x02], [0x03], [0x04], [0x03]]
        end
        @testset "op_pick" begin
            stack = Array{UInt8,1}[[0x01]]
            @test op_pick(stack) == false
            stack = [[0x01], [0x0b], [0x03], [0x05]]
            @test op_pick(stack) == false
            stack = [[0x01], [0x0b], [0x03], [0x02]]
            @test op_pick(stack) == true
            @test stack == [[0x01], [0x0b], [0x03], [0x0b]]
        end
        @testset "op_roll" begin
            stack = Array{UInt8,1}[]
            @test op_roll(stack) == false
            stack = [[0x01], [0x02], [0x03], [0x04]]
            @test op_roll(stack) == false
            @test stack == [[0x01], [0x02], [0x03]]
            stack = [[0x01], [0x0b], [0x03], [0x00]]
            @test op_roll(stack) == true
            @test stack == [[0x01], [0x0b], [0x03]]
            stack = [[0x01], [0x0b], [0x03], [0x02]]
            @test op_roll(stack) == true
            @test stack == [[0x01], [0x03], [0x0b]]
        end
        @testset "op_rot" begin
            stack = [[0x01], [0x02]]
            @test op_rot(stack) == false
            stack = [[0x01], [0x02], [0x03], [0x04]]
            @test op_rot(stack) == true
            @test stack == [[0x01], [0x03], [0x04], [0x02]]
        end
        @testset "op_swap" begin
            stack = [[0x01]]
            @test op_swap(stack) == false
            stack = [[0x01], [0x02], [0x03], [0x04]]
            @test op_swap(stack) == true
            @test stack == [[0x01], [0x02], [0x04], [0x03]]
        end
        @testset "op_tuck" begin
            stack = [[0x01]]
            @test op_tuck(stack) == false
            stack = [[0x01], [0x02], [0x03], [0x04]]
            @test op_tuck(stack) == true
            @test stack == [[0x01], [0x02], [0x04], [0x03], [0x04]]
        end
    end
    @testset "String splice operations" begin
        @testset "op_size" begin
            stack = Array{UInt8,1}[]
            @test op_size(stack) == false
            stack = [[0x01], [0x02], [0x01, 0x08]]
            @test op_size(stack) == true
            @test stack == [[0x01], [0x02], [0x01, 0x08], [0x02]]
        end
    end
    @testset "Binary arithmetic and conditionals" begin
        @testset "op_equal" begin
            stack = Array{UInt8,1}[]
            @test op_equal(stack) == false
            stack = [[0x01], [0x02], [0x03], [0x04]]
            @test op_equal(stack) == true
            @test stack == [[0x01], [0x02], []]
            stack = [[0x01], [0x02], [0x03], [0x03]]
            @test op_equal(stack) == true
            @test stack == [[0x01], [0x02], [0x01]]
        end
        @testset "op_equalverify" begin
            stack = Array{UInt8,1}[]
            @test op_equalverify(stack) == false
            stack = [[0x01], [0x02], [0x03], [0x04]]
            @test op_equalverify(stack) == false
            stack = [[0x01], [0x02], [0x03], [0x03]]
            @test op_equalverify(stack) == true
        end
    end
    @testset "Numeric operators" begin
        empty = Array{UInt8,1}[]
        stack = Array{UInt8,1}[[0x03]]
        @testset "op_1add" begin
            @test op_1add(empty) == false
            @test op_1add(stack) == true
            @test stack == [[0x04]]
        end
        @testset "op_1sub" begin
            @test op_1sub(empty) == false
            @test op_1sub(stack) == true
            @test stack == [[0x03]]
        end
        @testset "op_negate" begin
            @test op_negate(empty) == false
            @test op_negate(stack) == true
            @test stack == [[0x83]]
        end
        @testset "op_abs" begin
            @test op_abs(empty) == false
            @test op_abs(stack) == true
            @test stack == [[0x03]]
            @test op_abs(stack) == true
            @test stack == [[0x03]]
        end
        @testset "op_not" begin
            @test op_not(empty) == false
            @test op_not(stack) == true
            @test stack == [UInt8[]]
            @test op_not(stack) == true
            @test stack == [[0x01]]
        end
        @testset "op_0notequal" begin
            @test op_0notequal(empty) == false
            stack = [[0x1a]]
            @test op_0notequal(stack) == true
            @test stack == [[0x01]]
            stack = [[0x00]]
            @test op_0notequal(stack) == true
            @test stack == [UInt8[]]
        end
        @testset "op_add" begin
            @test op_add(empty) == false
            stack = [[0x09], [0x02], [0x03]]
            @test op_add(stack) == true
            @test stack == [[0x09], [0x05]]
        end
        @testset "op_sub" begin
            @test op_sub(empty) == false
            @test op_sub(stack) == true
            @test stack == [[0x04]]
        end
        @testset "op_booland" begin
            @test op_booland(empty) == false
            stack = [[0x00], [0x00]]
            @test op_booland(stack) == true
            @test stack == [UInt8[]]
            stack = [[0x01], [0x00]]
            @test op_booland(stack) == true
            @test stack == [UInt8[]]
            stack = [[0x00], [0x01]]
            @test op_booland(stack) == true
            @test stack == [UInt8[]]
            stack = [[0x01], [0x01]]
            @test op_booland(stack) == true
            @test stack == [UInt8[0x01]]
        end
        @testset "op_boolor" begin
            @test op_boolor(empty) == false
            stack = [[0x00], [0x00]]
            @test op_boolor(stack) == true
            @test stack == [UInt8[]]
            stack = [[0x00], [0x01]]
            @test op_boolor(stack) == true
            @test stack == [UInt8[0x01]]
            stack = [[0x01], [0x00]]
            @test op_boolor(stack) == true
            @test stack == [UInt8[0x01]]
            stack = [[0x01], [0x01]]
            @test op_boolor(stack) == true
            @test stack == [UInt8[0x01]]
        end
        @testset "op_numequal" begin
            @test op_numequal(empty) == false
            stack = [[0x01], [0x02], [0x00], [0x00]]
            @test op_numequal(stack) == true
            @test stack == [[0x01], [0x02], [0x01]]
            @test op_numequal(stack) == true
            @test stack == [[0x01], UInt8[]]
        end
        @testset "op_numequalverify" begin
            @test op_numequalverify(empty) == false
            stack = [[0x01], [0x02], [0x00], [0x00]]
            @test op_numequalverify(stack) == true
            @test stack == [[0x01], [0x02]]
            @test op_numequalverify(stack) == false
            @test stack == empty
        end
        @testset "op_numnotequal" begin
            @test op_numnotequal(empty) == false
            stack = [[0x01], [0x02], [0x03], [0x03]]
            @test op_numnotequal(stack) == true
            @test stack == [[0x01], [0x02], UInt8[]]
            stack = [[0x01], [0x02], [0x03], [0x04]]
            @test op_numnotequal(stack) == true
            @test stack == [[0x01], [0x02], [0x01]]
        end
        @testset "op_lessthan" begin
            @test op_lessthan(empty) == false
            stack = [[0x01], [0x01], [0x03], [0x04]]
            @test op_lessthan(stack) == true
            @test stack == [[0x01], [0x01], [0x01]]
            @test op_lessthan(stack) == true
            @test stack == [[0x01], UInt8[]]
        end
        @testset "op_greaterthan" begin
            @test op_greaterthan(empty) == false
            stack = [[0x04], [0x01], [0x02], [0x01]]
            @test op_greaterthan(stack) == true
            @test stack == [[0x04], [0x01], [0x01]]
            @test op_greaterthan(stack) == true
            @test stack == [[0x04], UInt8[]]
        end
        @testset "op_lessthanorequal" begin
            @test op_lessthanorequal(empty) == false
            stack = [[0x01], [0x02], [0x04], [0x04]]
            @test op_lessthanorequal(stack) == true
            @test stack == [[0x01], [0x02], [0x01]]
            @test op_lessthanorequal(stack) == true
            @test stack == [[0x01], UInt8[]]
        end
        @testset "op_greaterthanorequal" begin
            @test op_greaterthanorequal(empty) == false
            stack = [[0x04], [0x00], [0x02], [0x02]]
            @test op_greaterthanorequal(stack) == true
            @test stack == [[0x04], [0x00], [0x01]]
            @test op_greaterthanorequal(stack) == true
            @test stack == [[0x04], UInt8[]]
        end
        @testset "op_min" begin
            @test op_min(empty) == false
            stack = [[0x01], [0x08], [0x03], [0x04]]
            @test op_min(stack) == true
            @test stack == [[0x01], [0x08], [0x03]]
            @test op_min(stack) == true
            @test stack == [[0x01], [0x03]]
        end
        @testset "op_max" begin
            @test op_max(empty) == false
            stack = [[0x01], [0x08], [0x03], [0x04]]
            @test op_max(stack) == true
            @test stack == [[0x01], [0x08], [0x04]]
            @test op_max(stack) == true
            @test stack == [[0x01], [0x08]]
        end
        @testset "op_within" begin
            @test op_within(empty) == false
            stack = [[0xa1], [0x02], [0x02], [0x04]]
            @test op_within(stack) == true
            @test stack == [[0xa1], [0x01]]
            stack = [[0xa1], [0x08], [0x02], [0x04]]
            @test op_within(stack) == true
            @test stack == [[0xa1], UInt8[]]
        end
    end
    @testset "Cryptographic and hashing operations" begin
        empty = Array{UInt8,1}[]
        stack = Array{UInt8,1}[[0x03], [0x04]]
        @testset "op_ripemd160" begin
            @test op_ripemd160(empty) == false
            @test op_ripemd160(stack) == true
            @test stack == Array{UInt8,1}[[0x03], [0x44, 0x9b, 0x34, 0xb6, 0xa3, 0x41, 0x19, 0x43, 0xe3, 0x3a, 0x25, 0x87, 0xeb, 0xf2, 0x81, 0xca, 0xff, 0x16, 0x74, 0x98]]
        end
        stack = Array{UInt8,1}[[0x03], [0x04]]
        @testset "op_sha1" begin
            @test op_sha1(empty) == false
            @test op_sha1(stack) == true
            @test stack == Array{UInt8,1}[[0x03], [0xa4, 0x2c, 0x6c, 0xf1, 0xde, 0x3a, 0xbf, 0xde, 0xa9, 0xb9, 0x5f, 0x34, 0x68, 0x7c, 0xbb, 0xe9, 0x2b, 0x9a, 0x73, 0x83]]
        end
        stack = Array{UInt8,1}[[0x03], [0x04]]
        @testset "op_sha256" begin
            @test op_sha256(empty) == false
            @test op_sha256(stack) == true
            @test stack == Array{UInt8,1}[[0x03], [0xe5, 0x2d, 0x9c, 0x50, 0x8c, 0x50, 0x23, 0x47, 0x34, 0x4d, 0x8c, 0x07, 0xad, 0x91, 0xcb, 0xd6, 0x06, 0x8a, 0xfc, 0x75, 0xff, 0x62, 0x92, 0xf0, 0x62, 0xa0, 0x9c, 0xa3, 0x81, 0xc8, 0x9e, 0x71]]
        end
        stack = Array{UInt8,1}[[0x03], [0x04]]
        @testset "op_hash160" begin
            @test op_hash160(empty) == false
            @test op_hash160(stack) == true
            @test stack == Array{UInt8,1}[[0x03], [0x6d, 0x4c, 0x0a, 0xa9, 0x72, 0xc3, 0x14, 0x84, 0x0a, 0xc0, 0x7b, 0xe9, 0x6c, 0x5d, 0xde, 0x9c, 0x71, 0x4c, 0x9c, 0xa4]]
        end
        stack = Array{UInt8,1}[[0x03], [0x04]]
        @testset "op_hash256" begin
            @test op_hash256(empty) == false
            @test op_hash256(stack) == true
            @test stack == Array{UInt8,1}[[0x03], [0x21, 0x4e, 0x63, 0xbf, 0x41, 0x49, 0x0e, 0x67, 0xd3, 0x44, 0x76, 0x77, 0x8f, 0x67, 0x07, 0xaa, 0x6c, 0x8d, 0x2c, 0x8d, 0xcc, 0xdf, 0x78, 0xae, 0x11, 0xe4, 0x0e, 0xe9, 0xf9, 0x1e, 0x89, 0xa7]]
        end
        # TODO
        @testset "op_codeseparator" begin
        end
        # TODO
        @testset "op_checksig" begin
        end
        # TODO
        @testset "op_checksigverify" begin
        end
        # TODO
        @testset "op_checkmultisig" begin
        end
        # TODO
        @testset "op_checkmultisigverify" begin
        end
    end
    @testset "Nonoperators" begin
    end
    @testset "Reserved OP codes for internal use by the parser operators" begin
    end
end
