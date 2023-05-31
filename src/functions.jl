const headerscheme = Dict(
    "Time" => "time", 
    "wavelength" => "wavelength", 
    "wavenum" => "wavenumber",
    "CH0_ON_" => "on",
    "CH0_OFF_" => "off",
    "CH0_diff_" => "diff"
    )

"""
    readlvm(file; name="sample", grating=nothing, pumpdelay=nothing)

Read a LabView Measurement file (.lvm) and return a `DataFrame` of the data with metadata.

Arguments and units
- `file`: the path to the .lvm file.
- `name`: the name of the sample.
- `grating`: the grating wavelength in nm.
- `delay`: the pump delay in ps.
- `cal`: the grating calibration factor in nm.
"""
function readlvm(file; name="sample", grating=0, delay=0, cal=0.0)

    headerindices = Int[]
    headers = []
    df = DataFrame()

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
                    df[!, val] = chunk[:, h]
                else
                    df[!, header] = chunk[:, h]
                end
            end
        end
    end

    filename = split(file, "/")[end]
    datetime = get_datetime(filename)
    metadata!(df, "name", name)
    metadata!(df, "datetime", datetime)
    metadata!(df, "delay", delay)
    metadata!(df, "grating", grating)
    metadata!(df, "calibration", cal)
    
    return df
end

"""
    readlvm(dir, timestamp; prefix="sig", name="sample", grating=nothing, pumpdelay=nothing)

Read a LabView Measurement file (.lvm) and return a `DataFrame` of the data with metadata.

Arguments and units
- `file`: the path to the .lvm file.
- `name`: the name of the sample.
- `grating`: the grating wavelength in nm.
- `delay`: the pump delay in ps.
- `cal`: the grating calibration factor in nm.
"""
function readlvm(dir, timestamp; prefix="sig", name="sample", grating=0, delay=0, cal=0.0)

    file = make_filename(dir, timestamp; prefix)

    headerindices = Int[]
    headers = []
    df = DataFrame()

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
                    df[!, val] = chunk[:, h]
                else
                    df[!, header] = chunk[:, h]
                end
            end
        end
    end

    filename = split(file, "/")[end]
    datetime = get_datetime(filename)
    metadata!(df, "name", name)
    metadata!(df, "datetime", datetime)
    metadata!(df, "delay", delay)
    metadata!(df, "grating", grating)
    metadata!(df, "calibration", cal)
    
    return df
end

"""
    make_filename(dir, timestamp; prefix = "sig")

Make a filename for a LVM file from the path to a file and the file timestamp
(not including the date).
"""
function make_filename(dir, timestamp; prefix = "sig")
    if last(dir) == '/'
        dir = dir[1:end-1]
    end
    date = split(dir, "/")[end]
    filename = string(prefix, "_", date, "_", string(timestamp), ".lvm")
    return joinpath(dir, filename)
end

"""
    get_datetime(filename)

Get the DateTime from the filename of a LVM file.
"""
function get_datetime(filename)
    date = split(filename, "_")[2]
    time = split(split(filename, "_")[3], ".")[1]
    return DateTime(string(date, " ", time), "yymmdd HHMMSS") + Dates.Year(2000)
end