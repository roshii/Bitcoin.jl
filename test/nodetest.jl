@testset "Simple Node" begin
    @testset "Handshake" begin
        node = Node("tbtc.brane.cc", true)
        @test typeof(Bitcoin.handshake(node)[1]) == VersionMessage
    end
    # @testset "GetHeaders" begin
    #     node = Node("btc.brane.cc", false)
    #     Bitcoin.handshake(node)
    #     Bitcoin.geatheaders(node, 100)
    #     Bitcoin.close(node)
    # end
end
