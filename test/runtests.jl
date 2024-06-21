using Test
using Statistics
using LVM

dir = abspath("../testdata/230523")
timestamp_int = 152930
timestamp_str = string(timestamp_int)

@testset "readlvm" begin
    df = readlvm(dir, timestamp_int)
    df.on[3] = -0.458425
    df.diff[5] = -0.009435
    df.wavelength[end - 1] = 4998.0
    
    tmp1 = readlvm(joinpath(dir, "TEMP", "tmp_230523_150915.lvm"))
    tmp2 = readlvm(joinpath(dir, "TEMP", "tmp_230523_151600.lvm"))
    tmp3 = readlvm(joinpath(dir, "TEMP", "tmp_230523_152245.lvm"))
    
    scans = hcat(tmp1.diff, tmp2.diff, tmp3.diff)
    std_devs = std(scans, dims=2)
    sd_lvm(dir, timestamp_int, "diff", 3) == std_devs
end