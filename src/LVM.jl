module LVM

function read(file::String)

    headerindex = Int[]
    headers = []
    data = Dict()

    for (i, line) in enumerate(eachline(file))

        first_item = findfirst('\t', line)

        if first_item > 13

            if occursin('\r', line)
                header = split(line[1:findfirst('\r', line)])
            else
                header = split(line)
            end
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

        for (i, line) in enumerate(lines)
            for (j, item) in enumerate(split(line))
                chunk[i, j] = parse(Float64, item)
            end
        end

        for (k, header) in enumerate(headers[i])

            if occursin("wavelength", header)
                data["Wavelength"] = chunk[:, k]
            end

            if occursin("CH0_diff", header)
                data["DiffSignal"] = chunk[:, k]
            elseif occursin("CH0_", header)
                data["Signal"] = chunk[:, k]
            end
        end

    end
    
    return data
end

end # module