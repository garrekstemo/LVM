const headerscheme = Dict(
    "Time" => "time", 
    "wavelength" => "wavelength", 
    "wavenum" => "wavenumber",
    "CH0_ON_" => "on",
    "CH0_OFF_" => "off",
    "CH0_diff_" => "diff",
    "CH0tmp_ON_" => "on",
    "CH0tmp_OFF_" => "off",
    "CH0tmp_diff_" => "diff"
    )

"""
    readlvm(file; wavelength, delay)

Read a LabView Measurement file (.lvm) and return a `DataFrame` of the data with metadata.

Arguments and units
- `file`: the path of the .lvm file.
- `wavelength`: the grating wavelength in nm.
- `delay`: the pump delay in ps.
"""
function readlvm(file; wavelength=0, delay=0)

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
    return df
end

"""
    readlvm(dir, timestamp; prefix, wavelength, delay)
"""
function readlvm(dir, timestamp; prefix="sig", wavelength=0, delay=0)
    readlvm(make_filename(dir, timestamp; prefix), wavelength=wavelength, delay=delay)
end

function readlvm(dir, timestamp, nscans; prefix="sig", wavelength=0, delay=0)
    df = readlvm(make_filename(dir, timestamp; prefix), wavelength=wavelength, delay=delay)

    all_tmp_files = filter(x -> !(contains(x, "debug")), readdir(joinpath(dir, "TEMP")))
    times = @. Dates.format(Time(get_datetime(all_tmp_files)), "HHMMSS")
    last_tmp = searchsortedlast(times, string(timestamp))
    tmpfiles = all_tmp_files[last_tmp - nscans + 1:last_tmp]

    no_average = ["wavelength", "wavenumber", "time"]
  
    sd_dfs = DataFrame[]
    for tmpfile in tmpfiles
        df_tmp = readlvm(joinpath(dir, "TEMP", tmpfile), wavelength=wavelength, delay=delay)
        push!(sd_dfs, df_tmp)
    end
    for (key, header) in headerscheme
        df_tmp = DataFrame()
        if !(header in no_average)
            new_header = header * "_sd"
            # df_tmp[!, new_header] = std.([df_tmp[!, header] for df_tmp in sd_dfs]; dims=1)
            dfs = [df for df in sd_dfs]
            # st_dev = std(df_tmp[!, header])
            println(length(dfs))
        end
    end
    df
end

"""
    sd_lvm(dir, timestamp, ycol, nscans=1; wavelength=0, delay=0)

Calculate the standard error of measurement on the tmp files
given an averaged measurement file name.

ycol: the column to calculate the standard error of measurement on.
nscans: the number of scans to average over.
"""
function sd_lvm(dir, timestamp, ycol, nscans=1; wavelength=0, delay=0)
    all_tmp_files = filter(x -> !(contains(x, "debug")), readdir(joinpath(dir, "TEMP")))
    times = @. Dates.format(Time(get_datetime(all_tmp_files)), "HHMMSS")
    last_tmp = searchsortedlast(times, string(timestamp))
    tmpfiles = all_tmp_files[last_tmp - nscans + 1:last_tmp]
    tmp_dfs = []
    for tmpfile in tmpfiles
        tmpdf = readlvm(joinpath(dir, "TEMP", tmpfile), wavelength=wavelength, delay=delay)
        push!(tmp_dfs, tmpdf[!, ycol])
    end
    tmp_dfs = hcat(tmp_dfs...)
    return std(tmp_dfs, dims=2)
end

"""
    make_filename(dir, timestamp; prefix)

Make a filename for a LVM file from the path to a file and the file timestamp
(not including the date). The date is taken from the directory name,
which has the format "yymmdd".
"""
function make_filename(dir, timestamp; prefix = "sig")
    date = splitpath(dir)[end]
    if prefix == "tmp"
        filepath = splitpath(dir)
        if filepath[end] != "TEMP"
            dir = joinpath(dir, "TEMP")
        end
        date = splitpath(dir)[end-1]
    end
    filename = string(prefix, "_", date, "_", string(timestamp), ".lvm")
    return joinpath(dir, filename)
end

"""
    get_datetime(filename)

Get the `DateTime` from the file name of a LVM file.
Does not take path to file, just the file name.
"""
function get_datetime(filename)
    date = split(filename, "_")[2]
    time = split(split(filename, "_")[3], ".")[1]
    return DateTime(string(date, " ", time), "yymmdd HHMMSS") + Dates.Year(2000)
end