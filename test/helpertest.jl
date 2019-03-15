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
        want = [0xfe, 0xff, 0xff, 0xff, 0xff]
        @test Bitcoin.encode_varint(0x100000000-1) == want
        want = [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]
        @test Bitcoin.encode_varint(0x10000000000000000-1) == want
        @test_throws UndefVarError encode_varint(0x10000000000000000)
    end
    @testset "VarString" begin
        @testset "Serialize" begin
            want = hex2bytes("0f2f5361746f7368693a302e372e322f")
            vstr = Bitcoin.VarString("/Satoshi:0.7.2/")
            @test Bitcoin.serialize(vstr) == want
        end
    end
end
