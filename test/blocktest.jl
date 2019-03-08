@testset "Block" begin
    block_raw = hex2bytes("020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d")
    stream = IOBuffer(block_raw)
    block = Bitcoin.blockparse(stream)
    @test block.version == 0x20000002
    want = hex2bytes("000000000000000000fd0c220a0a8c3bc5a7b487e8c8de0dfa2373b12894c38e")
    @test block.prev_block == want
    want = hex2bytes("be258bfd38db61f957315c3f9e9c5e15216857398d50402d5089a8e0fc50075b")
    @test block.merkle_root == want
    @test block.timestamp == 0x59a7771e
    @test block.bits == hex2bytes("e93c0118")
    @test block.nonce == hex2bytes("a4ffd71d")
end
