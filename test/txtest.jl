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

@testset "Transaction" begin
    raw_tx = hex2bytes("0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf8303c6a989c7d1000000006b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278afeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac19430600")
    @testset "Parsing" begin
        @testset "Version" begin
            stream = IOBuffer(raw_tx)
            tx = txparse(stream)
            @test tx.version == 1
        end
        @testset "Inputs" begin
            stream = IOBuffer(raw_tx)
            tx = txparse(stream)
            @test length(tx.tx_ins) == 1
            want = hex2bytes("d1c789a9c60383bf715f3f6ad9d14b91fe55f3deb369fe5d9280cb1a01793f81")
            @test tx.tx_ins[1].prev_tx == want
            @test tx.tx_ins[1].prev_index == 0
            want = hex2bytes("6b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278a")
            @test Bitcoin.scriptserialize(tx.tx_ins[1].script_sig) == want
            @test tx.tx_ins[1].sequence == 0xfffffffe
        end
        @testset "Outputs" begin
            stream = IOBuffer(raw_tx)
            tx = txparse(stream)
            @test length(tx.tx_outs) == 2
            want = 32454049
            @test tx.tx_outs[1].amount == want
            want = hex2bytes("1976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac")
            @test Bitcoin.scriptserialize(tx.tx_outs[1].script_pubkey) == want
            want = 10011545
            @test tx.tx_outs[2].amount == want
            want = hex2bytes("1976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac")
            @test Bitcoin.scriptserialize(tx.tx_outs[2].script_pubkey) == want
        end
        @testset "Locktime" begin
            stream = IOBuffer(raw_tx)
            tx = txparse(stream)
            @test tx.locktime == 410393
        end
    end
    @testset "Serialize" begin
        stream = IOBuffer(raw_tx)
        tx = txparse(stream)
        @test txserialize(tx) == raw_tx
    end
    @testset  "Input Value" begin
        tx_hash = "d1c789a9c60383bf715f3f6ad9d14b91fe55f3deb369fe5d9280cb1a01793f81"
        index = 1
        want = 42505594
        tx_in = Bitcoin.TxIn(hex2bytes(tx_hash), index)
        @test Bitcoin.txinvalue(tx_in) == want
    end
end
