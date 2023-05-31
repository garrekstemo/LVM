const headerscheme = Dict(
    "Time" => "time", 
    "wavelength" => "wavelength", 
    "wavenum" => "wavenumber",
    "CH0_ON_" => "on",
    "CH0_OFF_" => "off",
    "CH0_diff_" => "diff"
    )

function readlvm(file)

    headerindices = Int[]
    headers = []
    data = Dict{Any, Vector{Float64}}()

    for (i, line) in enumerate(eachline(file))
        first_item = "1"
        first_tab = findfirst('\t', line)
        first_return = findfirst('\r', line)

        if !(first_tab === nothing)
            first_item = line[1:first_tab]
        elseif !(first_return === nothing)
            first_item = line[1:first_return]
        end

        if tryparse(Float64, first_item) === nothing
            if occursin("\t\r", line)
                header = split(line[1:findfirst("\t\r", line)[1]])
            elseif occursin('\r', line)
                header = split(line[1:findfirst('\r', line)])
            end
            push!(headerindices, i)
            push!(headers, header)
        end
    end

    lines = readlines(file)
    for (i, headerindex) in enumerate(headerindices)

        # Because of the strange placement of '\r' and '\t\r'
        # characters in the headers, we have to separately grab the first line of data.
        # Otherwise, the first row of data is part of the header.
        # Then we can add the rest of the data in a loop, skipping the first row.

        firstline = lines[headerindex][findfirst('\r', lines[headerindex]):end]

        if headerindex == last(headerindices)
            datalines = lines[headerindex + 1:end]
        else
            datalines = lines[headerindex + 1:headerindices[i+1] - 1]
        end

        # We need the +1 row for the first line.
        chunk = Array{Float64}(undef, length(datalines) + 1, length(headers[i]))
        chunk[1, :] = [parse(Float64, x) for x in split(firstline, '\t')]

        for (j, line) in enumerate(datalines)
            for (k, item) in enumerate(split(line))
                chunk[j+1, k] = parse(Float64, item)
            end
        end

        for (h, header) in enumerate(headers[i])
            for (key, val) in headerscheme
                if occursin(key, header)
                    data[val] = chunk[:, h]
                else
                    data[header] = chunk[:, h]
                end
            end
        end
    end
    
    return data
end

"""
    get_datetime(filename)

get the DateTime from the filename of a LVM file.
"""
function get_datetime(filename)
    date = split(filename, "_")[2]
    time = split(split(filename, "_")[3], ".")[1]
    return DateTime(string(date, " ", time), "yymmdd HHMMSS") + Dates.Year(2000)
end