#!/bin/bash
#SBATCH -J vasp_job      # 作业名称
#SBATCH -N 1
#SBATCH --ntasks-per-node=96
#SBATCH -p chu,phys      # 分区
#SBATCH -t 96:00:00      # 最大运行时长

# --- 脚本设置 ---
set -e # 任何命令失败则立即退出

# ==============================================================================
# --- 用户配置区域 ---
# 修改以下变量以匹配你的环境和需求
# ==============================================================================

# --- VASP 可执行文件 ---
# 指定你要使用的VASP可执行文件的完整路径
# 带有hdf5输出、Wannier的自编译版本
VASP_EXECUTABLE="/home/yqyang/.local/bin/vasp_std" 
# VASP_EXECUTABLE="/home/yqyang/.local/bin/vasp_gam" 
# VASP_EXECUTABLE="/home/yqyang/.local/bin/vasp_ncl" 

# --- Intel OneAPI 环境 ---
INTEL_ONEAPI_BASE="/opt/intel/oneapi"
INTEL_SETVARS_SCRIPT="${INTEL_ONEAPI_BASE}/setvars.sh"

# --- 附加库路径 ---
# 你的 HDF5 库路径
HDF5_LIB_PATH="/home/yqyang/.local/hdf5-1.14.6-intel-parallel/lib"
# 你的 Wannier90 库所在的目录 (如果 libwannier.a 是静态链接到VASP的，这里主要用于动态链接的.so文件)
# 如果 libwannier.a 已经静态链接，通常不需要为它设置 LD_LIBRARY_PATH
# 但如果VASP在运行时由于某种原因需要动态查找其他Wannier相关的.so文件，则需要
WANNIER_LIB_DIR="/home/yqyang/.local/lib" # 包含 libwannier.a 的目录
# 其他系统级依赖库
EXTRA_SYSTEM_LIBS_PATH="/opt/libs"

# --- MPI 执行器 ---
# 通常是 srun，但可以根据集群MPI配置调整 (如 mpirun, mpiexec)
# 对于Slurm，srun通常是推荐的
MPI_RUNNER="srun --mpi=pmi2" # 或者其他如 "mpirun -np \$SLURM_NTASKS"

# ==============================================================================
# --- 工具函数 ---
# (这部分可以保持不变，它们很有用)
# ==============================================================================
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

log_section_start() {
    echo
    echo "================================================================================"
    log_info "$1"
    echo "================================================================================"
}

# ==============================================================================
# --- 脚本主逻辑 ---
# ==============================================================================

log_section_start "脚本执行开始 (作业: ${SLURM_JOB_NAME}, ID: ${SLURM_JOB_ID})"

# --- 1. 环境设置 ---
log_section_start "环境设置"

log_info "设置ulimit堆栈大小为unlimited..."
ulimit -s unlimited

log_info "加载Intel OneAPI环境: ${INTEL_SETVARS_SCRIPT}"
if [ -f "${INTEL_SETVARS_SCRIPT}" ]; then
    source "${INTEL_SETVARS_SCRIPT}" --force > /dev/null # 重定向 setvars.sh 的输出以保持日志清洁
    log_info "Intel OneAPI环境已加载。"
else
    log_error "Intel OneAPI setvars.sh 未找到: ${INTEL_SETVARS_SCRIPT}"
    exit 1
fi

# 构建 LD_LIBRARY_PATH
# 顺序: 用户特定库 > 系统附加库 > Intel库 (已由setvars.sh设置) > 原始LD_LIBRARY_PATH
# 确保不重复添加路径，并处理空路径情况
NEW_LD_LIBRARY_PATH=""
# 用户HDF5
if [ -d "${HDF5_LIB_PATH}" ]; then
    NEW_LD_LIBRARY_PATH="${HDF5_LIB_PATH}"
fi
# 用户Wannier90 (主要是为了.so，.a文件在编译时链接)
if [ -d "${WANNIER_LIB_DIR}" ]; then
    if [ -n "${NEW_LD_LIBRARY_PATH}" ]; then
        NEW_LD_LIBRARY_PATH="${NEW_LD_LIBRARY_PATH}:${WANNIER_LIB_DIR}"
    else
        NEW_LD_LIBRARY_PATH="${WANNIER_LIB_DIR}"
    fi
fi
# 系统附加库
if [ -d "${EXTRA_SYSTEM_LIBS_PATH}" ]; then
    if [ -n "${NEW_LD_LIBRARY_PATH}" ]; then
        NEW_LD_LIBRARY_PATH="${NEW_LD_LIBRARY_PATH}:${EXTRA_SYSTEM_LIBS_PATH}"
    else
        NEW_LD_LIBRARY_PATH="${EXTRA_SYSTEM_LIBS_PATH}"
    fi
fi
# 附加到现有的 LD_LIBRARY_PATH (由 setvars.sh 等设置)
if [ -n "${LD_LIBRARY_PATH}" ]; then # 如果LD_LIBRARY_PATH已存在且非空
    if [ -n "${NEW_LD_LIBRARY_PATH}" ]; then
        export LD_LIBRARY_PATH="${NEW_LD_LIBRARY_PATH}:${LD_LIBRARY_PATH}"
    fi # 如果 NEW_LD_LIBRARY_PATH 为空，则不改变现有的 LD_LIBRARY_PATH
else # 如果LD_LIBRARY_PATH不存在或为空
    export LD_LIBRARY_PATH="${NEW_LD_LIBRARY_PATH}"
fi
log_info "最终 LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"


log_info "检查VASP可执行文件: ${VASP_EXECUTABLE}"
if [ ! -x "${VASP_EXECUTABLE}" ]; then # 检查文件是否存在且可执行
    log_error "VASP可执行文件 ${VASP_EXECUTABLE} 未找到或不可执行!"
    log_error "请检查用户配置区域中的 'VASP_EXECUTABLE' 设置。"
    exit 1
fi
log_info "将使用的VASP: ${VASP_EXECUTABLE}"

# --- 2. 作业信息输出 ---
log_section_start "作业信息"
log_info "提交用户:                 ${USER}"
log_info "提交目录:                 ${SLURM_SUBMIT_DIR}"
log_info "当前工作目录:             $(pwd)" # 通常应该在 SLURM_SUBMIT_DIR 中运行
log_info "请求分区:                 ${SLURM_JOB_PARTITION}"
log_info "请求运行时长:             $(scontrol show job ${SLURM_JOB_ID} | grep -oP 'TimeLimit=\K[^ ]+')"
log_info "分配节点数量:             ${SLURM_JOB_NUM_NODES}"
log_info "每节点任务数:             ${SLURM_NTASKS_PER_NODE}"
log_info "总任务数 (MPI ranks):     ${SLURM_NTASKS}"
log_info "每任务CPU数 (for OpenMP): ${SLURM_CPUS_PER_TASK:-1}" # 若未设置，默认为1
# 如果VASP使用OpenMP, OMP_NUM_THREADS应等于SLURM_CPUS_PER_TASK
# export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1} # 如果VASP需要，取消此行注释
log_info "预计OMP线程数:            ${OMP_NUM_THREADS:-${SLURM_CPUS_PER_TASK:-1}}"
log_info "运行节点列表:             ${SLURM_JOB_NODELIST}"
echo "--------------------------------------------------------------------------------"
echo

# 移动到提交目录执行，这是标准做法
cd "${SLURM_SUBMIT_DIR}" || { log_error "无法进入提交目录 ${SLURM_SUBMIT_DIR}"; exit 1; }
log_info "已切换到工作目录: $(pwd)"

# --- 3. 执行VASP计算 ---
log_section_start "开始执行VASP计算"
log_info "使用的VASP命令: ${MPI_RUNNER} ${VASP_EXECUTABLE}"

# 执行VASP
${MPI_RUNNER} "${VASP_EXECUTABLE}"
VASP_EXIT_CODE=$? # 获取VASP的退出码

if [ ${VASP_EXIT_CODE} -eq 0 ]; then
    log_section_start "VASP计算成功完成"
else
    log_section_start "VASP计算失败 (退出码: ${VASP_EXIT_CODE})"
fi

log_section_start "脚本执行结束"
exit ${VASP_EXIT_CODE}
