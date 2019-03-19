@testset "Simple Node" begin
    @testset "Handshake" begin
        node = Node("btc.brane.cc", true)
        @test Bitcoin.handshake(node)
        Bitcoin.close!(node)
    end
    # @testset "GetHeaders" begin
    #     node = Node("btc.brane.cc", false)
    #     Bitcoin.handshake(node)
    #     Bitcoin.geatheaders(node, 100)
    #     Bitcoin.close(node)
    # end
end
