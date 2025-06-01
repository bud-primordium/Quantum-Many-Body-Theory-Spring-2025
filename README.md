# 2025春量子多体理论课程论文 - Si的GW近似

## 简介

本仓库用于存储“2025春量子多体理论”的课程论文相关的源数据与代码。所有计算和分析均基于VASP GW示例完成。

计算涉及到密度泛函理论（DFT）以及GW近似。GW近似是一种超越DFT处理电子激发态（特别是能隙）的有效方法。其核心思想是将电子的自能 $\Sigma$ 近似为单粒子格林函数 $G$ 与屏蔽库仑相互作用 $W$ 的乘积，即 $\Sigma = GW$。通过这种方法，可以更准确地预测材料的准粒子能量和带隙。

$$
(T+V_{ext}+V_h)\psi_{n{\bf k}}({\bf r})+\int d{\bf r}\Sigma({\bf r},{\bf r}', E_{n{\bf k}})\psi_{n{\bf k}}({\bf r}') = E_{n{\bf k}}\psi_{n{\bf k}}({\bf r})
$$

本仓库包含了从DFT基态计算、非占据态计算，到 $G_0W_0$ 和 $GW_0$ 计算，以及最终利用Wannier90进行能带插值的全过程数据和脚本。

## 仓库结构

```
.
├── data/                       # VASP计算的原始数据目录
│   ├── 1-1 groud-states-dft/   # 步骤1.1: DFT基态计算 (Si)
│   │   ├── INCAR, POSCAR, KPOINTS, POTCAR  # VASP输入文件
│   │   ├── OUTCAR, vasprun.xml, WAVECAR    # VASP主要输出文件
│   │   └── ...                 # 其他相关文件 (CHG, DOSCAR等)
│   ├── 1-2 unoccupied-states/  # 步骤1.2: 计算非占据态 (为G0W0准备)
│   │   ├── INCAR, WAVECAR (from 1-1)     # VASP输入文件
│   │   ├── OUTCAR, WAVEDER               # VASP主要输出，WAVEDER包含波函数导数
│   │   └── ...               
│   ├── 1-3 G0W0/               # 步骤1.3: G0W0计算
│   │   ├── INCAR, WAVECAR, WAVEDER (from 1-2) # VASP输入文件
│   │   ├── OUTCAR                          # 包含准粒子能量
│   │   ├── dielectric_function_IPA.dat     # 独立粒子近似介电函数
│   │   ├── dielectric_function_RPA.dat     # 随机相近似介电函数
│   │   └── ...               
│   ├── 2-1 GW0/                # 步骤2.1: GW0计算 (部分自洽)
│   │   ├── INCAR, WAVECAR, WAVEDER (from 1-2 or G0W0 output) # VASP输入文件
│   │   ├── OUTCAR                          # 包含迭代后的准粒子能量
│   │   └── ...               
│   └── 2-2 wannier-approximation/ # 步骤2.2: 使用Wannier90进行能带插值
│       ├── INCAR, WAVECAR (from 2-1)     # VASP输入文件 (ALGO=NONE)
│       ├── wannier90.win                 # Wannier90输入文件
│       ├── wannier90.wout                # Wannier90输出文件
│       ├── wannier90_band.dat            # Wannier插值能带数据
│       ├── band_DFT_vs_GW.png          # DFT与GW能带对比图
│       └── ...               
├── figures/                    # 关键结果图像
│   ├── band_struc_dft.png      # DFT计算的能带图
│   ├── dos_dft.png             # DFT计算的态密度图
│   ├── si_dos.pdf              # sumo绘制的出版级态密度图
│   ├── dielectric_function_ipa_rpa.png # IPA与RPA介电函数对比图
│   ├── band_gw.png             # GW0插值能带图
│   ├── band_DFT_vs_GW.png      # DFT与GW能带对比图
│   ├── si_cudic_diamond.pdf    # VESTA绘制的立方金刚石结构Si的晶体结构图
│   └── ...                     # 其他根据Plot.ipynb生成的图
├── Plot.ipynb                  # Jupyter Notebook，用于数据后处理和绘图
└── README.md                   # 本文件
```

## 主要工作流程

本仓库中的计算和分析流程遵循 VASP GW示例中的指导，主要步骤如下：

1.  **DFT 基态计算 (Ground States DFT)**
    *   目的：获得体硅材料的DFT基态波函数、能量、电荷密度等。
    *   对应目录：`data/1-1 groud-states-dft/`
    *   关键输入：`INCAR` (ISMEAR=-5, ENCUT=400), `POSCAR`, `KPOINTS` (6x6x6 Gamma中心网格), `POTCAR` (Si_GW)
    *   关键输出：`WAVECAR`, `CHGCAR`, `OUTCAR`, `vasprun.xml`

2.  **非占据态计算 (Unoccupied States Calculation)**
    *   目的：基于DFT基态的 `WAVECAR`，计算大量非占据态（空带），为GW计算提供完备的基组，并生成波函数对k的导数文件 `WAVEDER`。
    *   对应目录：`data/1-2 unoccupied-states/`
    *   关键输入：`INCAR` (NBANDS=64, ALGO=Exact, NELM=1, LOPTICS=T), `WAVECAR` (from step 1)
    *   关键输出：`WAVECAR` (包含更多能带), `WAVEDER`

3.  **$G_0W_0$ 计算 (Single-shot GW)**
    *   目的：执行单次（非自洽）$G_0W_0$ 计算，获得准粒子能量修正和带隙。
    *   对应目录：`data/1-3 G0W0/`
    *   关键输入：`INCAR` (ALGO=EVGW0, NELMGW=1, NBANDS=64), `WAVECAR` (from step 2), `WAVEDER` (from step 2)
    *   关键输出：`OUTCAR` (包含QP energies, Z factor), `vasprun.xml`, 计算介电函数 (`dielectric_function_IPA.dat`, `dielectric_function_RPA.dat`)

4.  **$GW_0$ 计算 (Partially Self-consistent GW)**
    *   目的：在 $G_0W_0$ 基础上进行部分自洽计算，仅迭代更新格林函数 $G$ 中的本征能量，直至准粒子能量收敛。
    *   对应目录：`data/2-1 GW0/`
    *   关键输入：`INCAR` (ALGO=EVGW0, NELMGW=3, NBANDS=64, NBANDSGW=16), `WAVECAR` (from step 2), `WAVEDER` (from step 2)
    *   关键输出：`OUTCAR` (包含多次迭代后的QP energies), `vasprun.xml`

5.  **Wannier90 能带插值 (Wannier Interpolation for Band Structure)**
    *   目的：利用 $GW_0$ 计算得到的准粒子能量，通过VASP与Wannier90接口，构建局域Wannier函数，并插值得到高对称路径上的 $GW_0$ 能带结构。
    *   对应目录：`data/2-2 wannier-approximation/`
    *   关键输入：`INCAR` (ALGO=NONE, LWANNIER90=T, NUM_WANN=8), `WAVECAR` (from step 4, 包含$GW_0$准粒子能量), `wannier90.win` (通过INCAR中的WANNIER90_WIN参数块生成)
    *   运行 `vasp_std` 生成 Wannier90 所需文件 (`wannier90.amn`, `wannier90.mmn`, `wannier90.eig` 等)。
    *   运行 `wannier90.x wannier90.win` 进行Wannier函数构造和性质计算。
    *   修改 `wannier90.win` 以绘制能带图，再次运行 `wannier90.x wannier90.win`。
    *   关键输出：`wannier90.wout`, `wannier90_band.dat`, `wannier90_band.gnu`, 以及通过 `gnuplot` 绘制的能带图 (`band_gw.png`, `band_DFT_vs_GW.png`等)。

6.  **数据分析与绘图 (Data Analysis and Plotting)**
    *   目的：对VASP和Wannier90的输出数据进行可视化处理。
    *   工具：`Plot.ipynb` (Jupyter Notebook)
    *   内容：绘制能带图、态密度图（DOS）、介电函数图谱等。
    *   输出图保存于：`figures/` 目录，部分特定计算步骤的图也可能保存在相应的 `data` 子目录中。

## 关键结果与讨论

通过上述计算流程，我们得到了体硅在不同近似水平下的电子结构性质。

*   **能隙（Band Gap）**: 
    *   DFT (PBE) 计算得到的硅的间接带隙约为 $0.6$ eV (具体数值依赖于K点网格的选取，声子修正等因素，此处为基于特定K点网格的近似值)。
    *   $G_0W_0$ 近似将带隙修正为约 $1.16$ eV ( $\Gamma$ 点的最高占据态能量为 $5.1235$ eV，X点附近的最低未占据态能量为 $6.2826$ eV)。
    *   经过3次迭代的 $GW_0$ 近似进一步将带隙修正为约 $1.22$ eV ( $\Gamma$ 点的最高占据态能量为 $5.0779$ eV，X点附近的最低未占据态能量为 $6.2999$ eV)。
    这些结果与实验值（约 $1.17$ eV at room temperature）相比，GW计算显著改善了DFT对带隙的低估问题。

*   **能带结构与态密度 (Band Structure and DOS)**:
    *   DFT和GW近似下的能带结构图、态密度图（DOS）清晰地展示了硅的电子结构特征。这些图像（如 `band_struc_dft.png`, `dos_dft.png`, `band_DFT_vs_GW.png`）均保存在 `figures/` 目录以及相关的 `data` 子目录中。
    *   通过Wannier90插值得到的GW能带结构，可以与DFT结果进行直接比较，分析准粒子修正对能带的影响。

*   **介电函数 (Dielectric Function)**:
    *   计算了独立粒子近似（IPA）和随机相近似（RPA）下的介电函数，用于分析材料的光学响应和屏蔽效应。相关图像（如 `dielectric_function_ipa_rpa.png`）保存在 `figures/` 目录。

详细的数据分析和绘图过程参见 `Plot.ipynb`。所有原始计算数据和主要输出文件（如OUTCAR, vasprun.xml）均保存在各自的 `data` 子目录中，可供进一步检查和分析。

## 如何运行/复现

1.  **环境准备**：确保已正确安装 VASP 和 Wannier90。其中 VASP 需启用Wannier90接口，且`Plot.ipynb`中`py4vasp`相关的后处理需开启`HDF5`功能，建议从源码重新编译 VASP。此外，Python 环境及相关库（见依赖项）用于数据后处理和绘图，gnuplot 用于某些脚本绘图。
2.  **执行计算**：
    *   按照“主要工作流程”部分描述的顺序，进入 `data/` 下的各个子目录。
    *   在每个子目录中，根据需要（例如，从上一步骤复制 `WAVECAR` 文件），然后运行VASP (`mpirun -np X vasp_std` 或类似命令，X为并行核心数)。
    *   对于 `data/2-2 wannier-approximation/` 目录，在运行VASP生成Wannier90所需文件后，还需要运行 `wannier90.x wannier90.win`。具体脚本和命令可参考该目录下的 `sub_vasp.sh` 和 `sub_wannier.sh` 。
3.  **数据分析与绘图**：打开并运行 `Plot.ipynb` 中的代码块，可以复现 `figures/` 目录中的部分图像，或进行进一步的数据分析。

## 依赖项

*   **VASP (Vienna Ab initio Simulation Package)**: 用于主要的DFT和GW计算。
*   **Wannier90**: 用于构建Wannier函数和能带插值。
*   **Python 3.x**: 用于数据处理和绘图。
    *   `numpy`
    *   `matplotlib`
    *   `py4vasp` (VASP官方后处理库)
    *   `pymatgen` (未启用`HDF5`输出可用其读取VASP输出)
*   **VESTA**: 用于可视化原子结构（如 `si_cudic_diamond.pdf`）。
*   **sumo**: 用于生成出版级态密度图。
*   **gnuplot**: 用于从 `wannier90_band.gnu` 生成能带图。


## 致谢

1.  衷心感谢本课程的授课教师张鹏飞老师一学期以来的辛勤付出与悉心指导。
2.  **本工作所采用的GW理论方法在PAW框架下的实现主要基于以下文献**：
    *   M. Shishkin and G. Kresse, "Implementation and Performance of the Frequency-Dependent $GW$ Method within the PAW Framework," *Physical Review B* **74**, 035101 (2006). DOI: [10.1103/PhysRevB.74.035101](https://doi.org/10.1103/PhysRevB.74.035101).
3.  感谢褚老师提供宝贵的计算资源。由于Wannier90在作者的MacBook M3架构上编译存在持续的bug，后续的Wannier90计算及相关流程均在课题组的Linux服务器上完成。
4.  感谢张成言学长的持续答疑与针对Hedin方程组的深入讨论，前辈扎实的理论功底和严谨的学术态度对本工作有重要启发，并引导作者更深入地理解了BSE方程与DMFT等进阶内容。
5.  感谢VASP官方提供的GW计算示例和相关文档，极大地帮助了本工作流程的设计与实现。