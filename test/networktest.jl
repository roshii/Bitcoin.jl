@testset "Network" begin
    @testset "Envelope" begin
        @testset "Parse" begin
            msg = hex2bytes("f9beb4d976657261636b000000000000000000005df6e0e2")
            stream = IOBuffer(msg)
            envelope = Bitcoin.io2envelope(stream)
            @test envelope.command == b"verack"
            @test envelope.payload == b""
            msg = hex2bytes("f9beb4d976657273696f6e0000000000650000005f1a69d2721101000100000000000000bc8f5e5400000000010000000000000000000000000000000000ffffc61b6409208d010000000000000000000000000000000000ffffcb0071c0208d128035cbc97953f80f2f5361746f7368693a302e392e332fcf05050001")
            stream = IOBuffer(msg)
            envelope = Bitcoin.io2envelope(stream)
            @test envelope.command == b"version"
            @test envelope.payload == msg[25:end]
        end
        @testset "Serialize" begin
            msg = hex2bytes("f9beb4d976657261636b000000000000000000005df6e0e2")
            stream = IOBuffer(msg)
            envelope = Bitcoin.io2envelope(stream)
            @test Bitcoin.serialize(envelope) == msg
            msg = hex2bytes("f9beb4d976657273696f6e0000000000650000005f1a69d2721101000100000000000000bc8f5e5400000000010000000000000000000000000000000000ffffc61b6409208d010000000000000000000000000000000000ffffcb0071c0208d128035cbc97953f80f2f5361746f7368693a302e392e332fcf05050001")
            stream = IOBuffer(msg)
            envelope = Bitcoin.io2envelope(stream)
            @test Bitcoin.serialize(envelope) == msg
        end
    end
    @testset "Message" begin
        @testset "Serialize" begin
            @testset "Version" begin
                v = VersionMessage(0, fill(0x00, 8))
                @test bytes2hex(Bitcoin.serialize(v)) == "7f11010000000000000000000000000000000000000000000000000000000000000000000000ffff000000008d20000000000000000000000000000000000000ffff000000008d200000000000000000102f626974636f696e2e6a6c3a302e312f0000000001"
            end
            @testset "GetHeaders" begin
                block_hex = "0000000000000000001237f46acddf58578a37e213d2a6edc4884a2fcad05ba3"
                gh = GetHeadersMessage(hex2bytes(block_hex))
                @test bytes2hex(Bitcoin.serialize(gh)) == "7f11010001a35bd0ca2f4a88c4eda6d213e2378a5758dfcd6af437120000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            end
        end
        @testset "Parse" begin
            @testset "Headers" begin
                hex_msg = "0200000020df3b053dc46f162a9b00c7f0d5124e2676d47bbe7c5d0793a500000000000000ef445fef2ed495c275892206ca533e7411907971013ab83e3b47bd0d692d14d4dc7c835b67d8001ac157e670000000002030eb2540c41025690160a1014c577061596e32e426b712c7ca00000000000000768b89f07044e6130ead292a3f51951adbd2202df447d98789339937fd006bd44880835b67d8001ade09204600"
                stream = IOBuffer(hex2bytes(hex_msg))
                headers = Bitcoin.PARSE_PAYLOAD[b"headers"](stream)
                @test length(headers.headers) == 2
            end
        end
    end
end
