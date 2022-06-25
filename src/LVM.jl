module LVM

function read(file::String; getall::Bool=false)

    headerindex = Int[]
    headers = []
    data = Dict()

    for (i, line) in enumerate(eachline(file))

        first_item = line[1:findfirst('\t', line)]

        if tryparse(Float64, first_item) === nothing
            if occursin('\r', line)
                header = split(line[1:findfirst('\r', line)])
            else
                header = split(line, '\t')
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
                data["wavelength"] = chunk[:, k]

            elseif occursin("wavenum", header)
                data["wavenumber"] = chunk[:, k]

            elseif getall == false
                if occursin("CH0_diff", header)
                    data["diffsignal"] = chunk[:, k]
                elseif occursin("CH0_", header)
                    data["signal"] = chunk[:, k]
                end
            else
                data[header] = chunk[:, k]
            end
        end
    end
    
    return data
end


end # module