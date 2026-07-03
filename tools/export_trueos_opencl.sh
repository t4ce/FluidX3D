#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "${script_dir}/.." && pwd)"
out_dir="${FLUIDX3D_TRUEOS_OUT_DIR:-${repo_dir}/trueos-out/fluidx3d}"
kernel_path="${out_dir}/fluidx3d_benchmark_kernel.opencl"
meta_path="${out_dir}/fluidx3d_benchmark_kernel.meta"

mkdir -p "${out_dir}"

cd "${repo_dir}"
make Linux -j"$(nproc)"

LD_LIBRARY_PATH="${repo_dir}/src/OpenCL/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" \
	FLUIDX3D_EXPORT_OPENCL="${kernel_path}" \
	FLUIDX3D_EXPORT_OPENCL_ONLY=1 \
	"${repo_dir}/bin/FluidX3D" "$@"

sha256="$(sha256sum "${kernel_path}" | awk '{print $1}')"
bytes="$(wc -c < "${kernel_path}" | tr -d ' ')"
git_rev="$(git rev-parse --short HEAD 2>/dev/null || true)"

{
	printf 'name=fluidx3d_benchmark_kernel\n'
	printf 'source=%s\n' "${kernel_path}"
	printf 'bytes=%s\n' "${bytes}"
	printf 'sha256=%s\n' "${sha256}"
	printf 'fluidx3d_git=%s\n' "${git_rev:-unknown}"
	printf 'opencl_build_options=-cl-std=CL<device> -cl-finite-math-only -cl-no-signed-zeros -cl-mad-enable\n'
	printf 'trueos_target=TRUEOS Intel OpenCL AOT bridge seed\n'
	printf 'note=%s\n' 'This is configured OpenCL C for the default FluidX3D benchmark setup; TRUEOS still needs AOT compilation/registry contract entries before it can execute it natively.'
} > "${meta_path}"

printf 'Exported %s (%s bytes)\n' "${kernel_path}" "${bytes}"
printf 'Metadata %s\n' "${meta_path}"
