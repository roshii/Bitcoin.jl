"""
    merkle_parent(hash1::Array{UInt8,1}, hash2::Array{UInt8,1})
    -> Array{UInt8,1}

Takes the binary hashes and calculates the hash256
"""
function merkle_parent(hash1::Array{UInt8,1}, hash2::Array{UInt8,1})
    hash256(append!(copy(hash1), hash2))
end

"""
    merkle_parent_level(Array{Array{UInt8,1},1})
    -> Array{Array{UInt8,1},1}

Takes a list of binary hashes and returns a list that's half
the length
Returns an error if the list has exactly 1 element
"""
function merkle_parent_level(hashes::Array{Array{UInt8,1},1})
    h = copy(hashes)
    if length(h) == 1
        error("Cannot take a parent level with only 1 item")
    end
    if length(h) % 2 == 1
        push!(h, h[end])
    end
    parent_level = Array{UInt8,1}[]
    for i in 1:2:length(h)
        parent = merkle_parent(h[i], h[i + 1])
        push!(parent_level, parent)
    end
    parent_level
end

"""
    merkle_root(hashes::Array{Array{UInt8,1},1})
    -> Array{UInt8,1}

Takes a list of binary hashes and returns the merkle root
"""
function merkle_root(hashes::Array{Array{UInt8,1},1})
    current_level = hashes
    while length(current_level) > 1
        current_level = merkle_parent_level(current_level)
    end
    current_level[1]
end
