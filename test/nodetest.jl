@testset "Simple Node" begin
    @testset "Handshake" begin
        node = Node("btc.brane.cc", true)
        @test Bitcoin.handshake(node)
        Bitcoin.close!(node)
    end
    # @testset "GetHeaders" begin
    #     node = Node("btc.brane.cc", false)
    #     @test typeof(Bitcoin.getheaders(node, 1)) == Array{Bitcoin.BlockHeader,1}
    #     Bitcoin.close!(node)
    # end
end
