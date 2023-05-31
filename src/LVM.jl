module LVM

export loadexperiment,
       experimentschemes,
       readlvm,
       lvm_to_df,
       get_datetime

using DataFrames
using Dates

include("functions.jl")


"""
    MIRFile

A mutable struct for storing MIR data.

Fields:
date::String
time::String
sample::String
pumpdelay::Int64
gratingwavelength::Int64
wavenumber::Vector{Float64}
wavelength::Vector{Float64}
time::Vector{Float64}
ΔA::Vector{Float64}

Units:
pumpdelay is in fs.
gratingwavelength is in nm.
wavenumber is in cm^-1.
wavelength is in nm.
time is in fs.
"""
mutable struct MIRFile
    datetime::DateTime          # DateTime type
    sample::String              # sample information
    pumpdelay::Int64            # fs
    gratingwavelength::Int64    # nm
    wavenumber::Vector{Float64} # cm^-1
    wavelength::Vector{Float64} # nm
    fs::Vector{Float64}         # fs
    ΔA::Vector{Float64} 

    function MIRFile(date::String, time::String, sample::String, pumpdelay::Int64, gratingwavelength::Int64, wavenumber::Vector{Float64}, wavelength::Vector{Float64}, time::Vector{Float64}, ΔA::Vector{Float64})
        new(date, time, sample, pumpdelay, gratingwavelength, wavenumber, wavelength, time, ΔA)
    end

    function MIRFile(filename)
        datetime = get_datetime(filename)
        dict = readlvm(filename, :MIR)
        fields = names(dict)
    # end

end

end # module