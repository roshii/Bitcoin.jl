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
        @testset "Version" begin
            v = VersionMessage(0, fill(0x00, 8))
            @test bytes2hex(Bitcoin.serialize(v)) == "7f11010000000000000000000000000000000000000000000000000000000000000000000000ffff000000008d20000000000000000000000000000000000000ffff000000008d200000000000000000102f626974636f696e2e6a6c3a302e312f0000000001"
        end
    end
end
