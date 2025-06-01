set style data dots
set nokey
set xrange [0: 5.19242]
set yrange [ -7.80784 : 17.02608]
set arrow from  1.15712,  -7.80784 to  1.15712,  17.02608 nohead
set arrow from  1.56623,  -7.80784 to  1.56623,  17.02608 nohead
set arrow from  2.79355,  -7.80784 to  2.79355,  17.02608 nohead
set arrow from  3.79564,  -7.80784 to  3.79564,  17.02608 nohead
set arrow from  4.61385,  -7.80784 to  4.61385,  17.02608 nohead
set xtics ("G"  0.00000,"X"  1.15712,"U|K"  1.56623,"G"  2.79355,"L"  3.79564,"W"  4.61385,"X"  5.19242)
 plot "wannier90_band.dat"
