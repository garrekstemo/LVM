module LVM

using DataFrames

function read(file::String)
    headerindex = Int[]
    headers = []
    data = Array{Float64}[]
    dfs = DataFrame[]

    for (i, line) in enumerate(eachline(file))

        first_item = findfirst('\t', line)

        if first_item > 13 
            header = split(line[1:findfirst('\r', line)])
            push!(headerindex, i)
            push!(headers, header)
        end
    end

    for (i, h) in enumerate(headerindex)

        if headerindex[i] == headerindex[end]
            lines = readlines(file)[h + 1:end]
        else
            lines = readlines(file)[h + 1 : headerindex[i + 1] - 1]
        end

        colsize = length(split(lines[1]))
        chunk = Array{Float64}(undef, length(lines), colsize)

        for (l, line) in enumerate(lines)
            line = [parse(Float64, x) for x in split(line)]
            chunk[l, :] = line
        end
        push!(data, chunk)

        df = DataFrame(chunk, headers[i])
        push!(dfs, df)

    end
    
    return dfs
end

end # module