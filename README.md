# LVM.jl

Simple tool for reading `.lvm` files or other tabular data with columns that are stacked. In traditional text files, a single column represents a distinct set of data of a single unit (intensity, wavelength, etc.). For example, the first column is `x` and the second column is `y` -- the `x` and `y` columns are represented by only one unit and the header (if there is one) appears at the top of the column. For some reason, I have a program that spits out data where there are columns `a`, `b`, `c`, `d` at the top, but then below these data are additional data `e` and `f`, with different units and with their own headers. The number of columns in each stack is also different, throwing up errors when trying to read these files. These `.lvm` files cannot simply be read by a program like `CSV.jl` and must be pre-processed.

This program takes these text files and returns a DataFrame for each stack of data that it finds in the file. If there are two stacks there will be a list of two DataFrames, for example.

Further data manipulation should be done with a package like `DataFrames.jl`.

Example of the offending text file type:

```
A   B   C
0.1 0.1 0.1
0.2 0.2 0.2
0.3 0.3 0.3
0.2 0.2 0.2
0.1 0.2 0.1
D   E
1   1
2   2
3   3
4   4
5   5
```