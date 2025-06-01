#!/bin/bash
# ==============================================================================
# --- Slurm 作业配置 (请编辑这些) ---
# ==============================================================================
#SBATCH -J wannier90          # 作业名称 (例如: my_program_run, data_analysis)
#SBATCH -N 1                    # 节点数量
#SBATCH --ntasks-per-node=96    # 每个节点的任务数 (MPI 进程数)
                                # 对于串行作业或纯 OpenMP 作业，通常为 1。
                                # 对于 MPI 作业，这是每个节点的 MPI 进程数。
#SBATCH --cpus-per-task=1       # 每个任务的 CPU核心数
                                # 对于串行作业，为 1。
                                # 对于 OpenMP 作业，设置为所需的线程数。
                                # 对于 MPI 作业，通常为 1 (除非是 MPI+OpenMP 混合模式)。
#SBATCH -p chu,phys             # 分区 (队列) 名称 (优先尝试chu)
#SBATCH -t 2:00:00              # 最大运行时长 (格式: D-HH:MM:SS 或 HH:MM:SS)
#SBATCH --output=%x_%j.out      # 标准输出文件名 (%x=作业名, %j=作业ID)
#SBATCH --error=%x_%j.err       # 标准错误文件名

# ==============================================================================
# --- 用户配置 (请编辑这些) ---
# 定义程序及其执行环境
# ==============================================================================

# --- 程序标识 ---
PROGRAM_NAME="Wannier90" # 用于日志记录的程序/任务的描述性名称

# --- 可执行文件 ---
# 选项 1: 程序在您的 PATH 环境变量中
PROGRAM_EXECUTABLE="wannier90.x"
# 选项 2: 指定可执行文件的完整路径
# PROGRAM_EXECUTABLE="/path/to/your/program_executable"

# --- 输入文件 (可选检查) ---
# 列出提交目录中预期的任何关键输入文件。
# 脚本将检查它们是否存在。
# 示例: REQUIRED_INPUT_FILES=("input.dat" "config.ini")
REQUIRED_INPUT_FILES=("wannier90.win")

# --- 程序参数 ---
# 传递给程序的参数。如果参数包含空格，请使用引号。
# 示例: PROGRAM_ARGUMENTS="input.file --option1 value1 --output 'output file.dat'"
PROGRAM_ARGUMENTS="${REQUIRED_INPUT_FILES[0]} "  #REQUIRED_INPUT_FILES是一个数组

# --- 并行配置 ---
# 设置为 "true" 或 "false"
ENABLE_MPI=true     # 这是一个 MPI 并行程序吗?是的话可以修改上面的SBATCH --ntasks-per-node
ENABLE_OPENMP=false  # 这个程序使用 OpenMP 线程吗?
                     # 如果为 true, OMP_NUM_THREADS 将被设置为 SLURM_CPUS_PER_TASK

# --- MPI 运行器 (如果 ENABLE_MPI 为 true) ---
# 常见选项: "srun --mpi=pmi2", "mpirun -np \$SLURM_NTASKS"
MPI_RUNNER_COMMAND="srun --mpi=pmi2"

# --- 环境变量模块 (可选) ---
# 列出要加载的模块，用空格分隔。
# 示例: MODULES_TO_LOAD="gcc/11.2.0 openmpi/4.1.1 python/3.9.7"
MODULES_TO_LOAD=""

# --- Intel OneAPI 环境 (可选) ---
# 设置为 "true" 或 "false"
LOAD_INTEL_ENV=true # 是否加载 Intel OneAPI setvars.sh? (例如，用于 MKL, Intel 编译器)
INTEL_ONEAPI_BASE="/opt/intel/oneapi"
INTEL_SETVARS_SCRIPT="${INTEL_ONEAPI_BASE}/setvars.sh"

# --- 自定义 LD_LIBRARY_PATH 添加项 (可选) ---
# 添加自定义共享库的路径，用冒号分隔。
# 示例: CUSTOM_LD_PATHS="$HOME/.local/custom_libs/lib:/opt/other_app/lib"
# 如果您之前在 VASP 中使用了 HDF5，并且您的其他程序也需要它:
CUSTOM_LD_PATHS="$HOME/.local/hdf5-1.14.6-intel-parallel/lib" 
EXTRA_SYSTEM_LIBS_PATH="/opt/libs" # 系统级的额外库路径，如果存在

# --- 执行前命令 (可选) ---
# 在主程序运行*之前*执行的命令 (例如，创建目录，复制文件)。
# 对于多个命令，请使用数组。
# 示例: PRE_EXEC_CMDS=("mkdir -p results" "cp data_template.txt working_data.txt")
PRE_EXEC_CMDS=()

# --- 执行后命令 (可选) ---
# 在主程序运行*之后*执行的命令，无论成功或失败，
# 或仅在成功时执行。(例如，归档结果，清理)。
# 示例: POST_EXEC_CMDS_ALWAYS=("tar -czf results_${SLURM_JOB_ID}.tar.gz results_dir")
# 示例: POST_EXEC_CMDS_ON_SUCCESS=("echo '分析完成' > SUCCESS_MARKER")
POST_EXEC_CMDS_ALWAYS=()
POST_EXEC_CMDS_ON_SUCCESS=()

# ==============================================================================
# --- 脚本设置 (通常无需编辑此行以下的内容) ---
# ==============================================================================
set -e # 如果任何命令以非零状态退出，则立即退出。
# set -u # 将未设置的变量视为错误。(有时有帮助，但可能过于严格)
# set -o pipefail # 使管道返回最后一个以非零状态退出的命令的退出状态，
                  # 或者如果管道中的所有命令都成功退出，则返回零。

# --- 工具函数 ---
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${SLURM_JOB_ID}] INFO: $1"
}
log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${SLURM_JOB_ID}] ERROR: $1" >&2
}
log_section_start() {
    echo
    log_info "================================================================================"
    log_info "$1"
    log_info "================================================================================"
}

# ==============================================================================
# --- 主脚本逻辑 ---
# ==============================================================================

log_section_start "开始 ${PROGRAM_NAME} 作业脚本"

# --- 1. 环境设置 ---
log_section_start "设置执行环境"

log_info "设置ulimit堆栈大小为unlimited。"
ulimit -s unlimited

# 加载指定的环境模块
if [ -n "${MODULES_TO_LOAD}" ]; then
    log_info "加载环境变量模块: ${MODULES_TO_LOAD}"
    module load ${MODULES_TO_LOAD} || { log_error "加载模块失败: ${MODULES_TO_LOAD}"; exit 1; }
    log_info "模块已加载。"
fi

# 如果请求，加载 Intel OneAPI 环境
if [ "${LOAD_INTEL_ENV}" = true ]; then
    if [ -f "${INTEL_SETVARS_SCRIPT}" ]; then
        log_info "从以下位置加载 Intel OneAPI 环境: ${INTEL_SETVARS_SCRIPT}"
        source "${INTEL_SETVARS_SCRIPT}" --force > /dev/null # 除非出错，否则抑制输出
        log_info "Intel OneAPI 环境已加载。"
    else
        log_error "未找到 Intel OneAPI setvars.sh: ${INTEL_SETVARS_SCRIPT}"
        exit 1
    fi
fi

# 配置 LD_LIBRARY_PATH
# 将自定义路径和系统额外路径前置到现有的 LD_LIBRARY_PATH
TEMP_LD_PATH=""
if [ -n "${CUSTOM_LD_PATHS}" ]; then
    TEMP_LD_PATH="${CUSTOM_LD_PATHS}"
fi
if [ -d "${EXTRA_SYSTEM_LIBS_PATH}" ]; then # 检查是否是目录
    if [ -n "${TEMP_LD_PATH}" ]; then
        TEMP_LD_PATH="${TEMP_LD_PATH}:${EXTRA_SYSTEM_LIBS_PATH}"
    else
        TEMP_LD_PATH="${EXTRA_SYSTEM_LIBS_PATH}"
    fi
fi
if [ -n "${TEMP_LD_PATH}" ]; then
    if [ -n "${LD_LIBRARY_PATH}" ]; then
        export LD_LIBRARY_PATH="${TEMP_LD_PATH}:${LD_LIBRARY_PATH}"
    else
        export LD_LIBRARY_PATH="${TEMP_LD_PATH}"
    fi
    log_info "更新后的 LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"
else
    log_info "此脚本未修改 LD_LIBRARY_PATH。当前: ${LD_LIBRARY_PATH:-<未设置>}"
fi


# 如果启用，配置 OpenMP
if [ "${ENABLE_OPENMP}" = true ]; then
    export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
    log_info "OpenMP 已启用。OMP_NUM_THREADS 设置为 ${OMP_NUM_THREADS} (来自 SLURM_CPUS_PER_TASK)。"
else
    # 如果此脚本未显式启用 OpenMP，则取消设置 OMP_NUM_THREADS，
    # 以避免如果父环境因其他原因设置了它而产生干扰。
    # 但是，如果未设置，某些程序可能会选择默认值。
    # 如果要确保对于非 OpenMP 程序其值为1：
    # export OMP_NUM_THREADS=1
    # log_info "脚本未显式启用 OpenMP。OMP_NUM_THREADS 保持: ${OMP_NUM_THREADS:-<未设置或默认为1>}"
    log_info "此脚本未为 ${PROGRAM_NAME} 显式启用 OpenMP。"
fi

# --- 2. 验证输入和可执行文件 ---
log_section_start "验证输入和程序可执行文件"

# 确定实际的可执行文件路径 (处理 PATH 中的程序或完整路径)
ACTUAL_PROGRAM_EXECUTABLE=""
if [[ "${PROGRAM_EXECUTABLE}" == */* ]]; then # 包含斜杠，假定是路径
    ACTUAL_PROGRAM_EXECUTABLE="${PROGRAM_EXECUTABLE}"
else # 不含斜杠，假定是 PATH 中的命令名
    ACTUAL_PROGRAM_EXECUTABLE=$(which "${PROGRAM_EXECUTABLE}" 2>/dev/null)
fi

if [ -z "${ACTUAL_PROGRAM_EXECUTABLE}" ]; then
    log_error "程序可执行文件 '${PROGRAM_EXECUTABLE}' 在 PATH 中或作为直接路径均未找到。"
    exit 1
fi
if [ ! -x "${ACTUAL_PROGRAM_EXECUTABLE}" ]; then
    log_error "程序可执行文件 '${ACTUAL_PROGRAM_EXECUTABLE}' 不可执行。"
    exit 1
fi
log_info "使用的程序可执行文件: ${ACTUAL_PROGRAM_EXECUTABLE}"

# 切换到提交目录
log_info "切换到提交目录: ${SLURM_SUBMIT_DIR}"
cd "${SLURM_SUBMIT_DIR}" || { log_error "切换到 ${SLURM_SUBMIT_DIR} 失败"; exit 1; }
log_info "当前工作目录: $(pwd)"

# 检查所需的输入文件
if [ ${#REQUIRED_INPUT_FILES[@]} -gt 0 ]; then
    log_info "在 $(pwd) 中检查所需的输入文件:"
    MISSING_FILE=false # 初始化标志
    for f in "${REQUIRED_INPUT_FILES[@]}"; do
        if [ -f "$f" ]; then
            log_info "  找到: $f"
        else
            log_error "  缺少必需的输入文件: $f"
            MISSING_FILE=true
        fi
    done
    if [ "${MISSING_FILE}" = true ]; then
        log_error "一个或多个必需的输入文件缺失。正在退出。"
        exit 1
    fi
else
    log_info "脚本未明确检查特定的输入文件。"
fi


# --- 3. 显示作业信息 ---
log_section_start "作业信息"
log_info "作业名称:                ${SLURM_JOB_NAME}"
log_info "作业 ID:                 ${SLURM_JOB_ID}"
log_info "用户:                    ${USER}"
log_info "提交目录:                ${SLURM_SUBMIT_DIR}"
log_info "工作目录:                $(pwd)"
log_info "分区:                    ${SLURM_JOB_PARTITION}"
log_info "节点数量:                ${SLURM_JOB_NUM_NODES}"
log_info "每节点任务数:            ${SLURM_NTASKS_PER_NODE}"
log_info "每任务 CPU 数:           ${SLURM_CPUS_PER_TASK}"
log_info "总任务数 (MPI Ranks):    ${SLURM_NTASKS}"
if [ "${ENABLE_OPENMP}" = true ]; then
log_info "OMP_NUM_THREADS:         ${OMP_NUM_THREADS}"
fi
log_info "节点列表:                ${SLURM_JOB_NODELIST}"
echo "--------------------------------------------------------------------------------"
echo

# --- 4. 执行前命令 ---
if [ ${#PRE_EXEC_CMDS[@]} -gt 0 ]; then
    log_section_start "执行预执行命令"
    for cmd in "${PRE_EXEC_CMDS[@]}"; do
        log_info "正在执行: $cmd"
        eval "$cmd" # 如果需要处理带引号/变量的复杂命令，请使用 eval
                    # 如果命令来自不受信任的来源，请谨慎使用。
        CMD_EXIT_CODE=$?
        if [ ${CMD_EXIT_CODE} -ne 0 ]; then
            log_error "预执行命令失败 (退出码 ${CMD_EXIT_CODE}): $cmd"
            exit ${CMD_EXIT_CODE}
        fi
    done
fi

# --- 5. 执行主程序 ---
log_section_start "执行 ${PROGRAM_NAME}"

# 构建命令行
# 注意：这种简单的字符串拼接方式对于包含空格或特殊字符的参数可能不够健壮。
# 更健壮的方法是使用数组来构建命令，或者小心地使用 `eval`。
# 对于 PROGRAM_ARGUMENTS，用户通常会自己处理好引号。
COMMAND_LINE=""
if [ "${ENABLE_MPI}" = true ]; then
    # 将 MPI 运行器和参数添加到命令中
    # SLURM_NTASKS 通常由 sbatch 指令 (--ntasks, --ntasks-per-node, -N) 决定
    # 如果 MPI_RUNNER_COMMAND 包含如 $SLURM_NTASKS 这样的变量，它会在执行时被shell扩展
    COMMAND_LINE+="${MPI_RUNNER_COMMAND} "
fi

# 添加可执行文件和参数
COMMAND_LINE+="${ACTUAL_PROGRAM_EXECUTABLE} ${PROGRAM_ARGUMENTS}"

log_info "完整命令: ${COMMAND_LINE}"

# 执行命令
# 使用 eval 可以处理 PROGRAM_ARGUMENTS 中可能包含的需要 shell 解释的元字符（例如重定向 '>', '<', '|'）。
# 但如果参数只是文件名和标志，直接执行更安全。
# 为了简单起见，这里直接执行，假设 PROGRAM_ARGUMENTS 的引号已正确处理。
# 如果遇到参数解析问题，考虑使用 eval 或将命令构建为数组。
eval "${COMMAND_LINE}"
PROGRAM_EXIT_CODE=$?

# --- 6. 程序执行结果 ---
if [ ${PROGRAM_EXIT_CODE} -eq 0 ]; then
    log_section_start "${PROGRAM_NAME} 成功完成"
    # 执行成功后的命令
    if [ ${#POST_EXEC_CMDS_ON_SUCCESS[@]} -gt 0 ]; then
        log_info "执行成功后命令:"
        for cmd in "${POST_EXEC_CMDS_ON_SUCCESS[@]}"; do
            log_info "正在执行: $cmd"
            eval "$cmd"
            CMD_EXIT_CODE=$?
            if [ ${CMD_EXIT_CODE} -ne 0 ]; then
                log_error "成功后命令失败 (退出码 ${CMD_EXIT_CODE}): $cmd"
                # 通常不在此处退出，主程序已成功
            fi
        done
    fi
else
    log_section_start "${PROGRAM_NAME} 执行失败 (退出码: ${PROGRAM_EXIT_CODE})"
fi

# --- 7. 执行后命令 (总是执行) ---
if [ ${#POST_EXEC_CMDS_ALWAYS[@]} -gt 0 ]; then
    log_section_start "执行总是运行的后处理命令"
    for cmd in "${POST_EXEC_CMDS_ALWAYS[@]}"; do
        log_info "正在执行: $cmd"
        eval "$cmd"
        CMD_EXIT_CODE=$?
        if [ ${CMD_EXIT_CODE} -ne 0 ]; then
            log_error "总是运行的后处理命令失败 (退出码 ${CMD_EXIT_CODE}): $cmd"
            # 通常不在此处修改主程序的退出码
        fi
    done
fi

log_section_start "脚本执行结束"
exit ${PROGRAM_EXIT_CODE}
