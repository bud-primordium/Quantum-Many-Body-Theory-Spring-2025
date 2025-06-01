set term png
set out 'band_DFT_vs_GW_2.png'

set title "Si Band Structure: DFT vs GW0"
set xlabel "k-vector"
set ylabel "Energy (eV)"

# 设置高对称点标签 (从wannier90_band.gnu中获取或手动设置)
set xtics ("G" 0.0, "X" 1.15712, "U|K" 1.56623, "G" 2.79355, "L" 3.79564, "W" 4.61385, "X" 5.19242)
# 根据你的k路径调整上面的数值和标签

# 假设GW VBM是 5.0779 (你需要用你自己的值)
GW_VBM = 5.0779
# 假设DFT VBM是 X.XXXX (你需要从DFT计算中得到，并可能需要调整能量参考点)
# 为了简单起见，我们先画绝对能量，然后用GW_VBM作为参考线

# 绘制 wannier90_band.dat (GW bands)
# 这里需要正确地绘制 wannier90_band.dat 中的所有能带
# 最简单的方法是，如果wannier90.x生成了wannier90_band.gnu,
# 其中通常有类似 "plot for [i=2:NUM_WANN+1] 'wannier90_band.dat' using 1:i with lines" 的命令
# 我们这里先假设一个简单的画法，你可能需要调整
plot 'wannier90_band.dat' using 1:2 w l title 'GW Band', \
     '' using 1:3 w l title 'GW Band 2', \
     '' using 1:4 w l title 'GW Band 3', \
     '' using 1:5 w l title 'GW Band 4', \
     '' using 1:6 w l title 'GW Band 5', \
     '' using 1:7 w l title 'GW Band 6', \
     '' using 1:8 w l title 'GW Band 7', \
     '' using 1:9 w l title 'GW Band 8', \
     'e01_kpoints_opt_band.dat' using 1:($2) w l lc rgb "blue" title "DFT (PBE)", \
     GW_VBM lt 0 lw 2 lc rgb "red" title sprintf("GW VBM = %.3f eV", GW_VBM)

# 或者，如果 e01_kpoints_opt_band.dat 是多段数据表示多条带：
# plot 'wannier90_band.dat' using 1:2 w l title 'GW Band 1', \
#      ... (其他GW能带) ..., \
#      'e01_kpoints_opt_band.dat' w l lc rgb "blue" title "DFT (PBE)", \
#      GW_VBM lt 0 lw 2 lc rgb "red" title sprintf("GW VBM = %.3f eV", GW_VBM)

