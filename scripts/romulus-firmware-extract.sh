#!/bin/bash

set -e  # Exit on error
set -u  # Treat unset variables as an error
set -o pipefail  # Catch errors in pipelines

# Define paths
device_path="microsoft/"
firmware_dir="/lib/firmware/updates/qcom/x1e80100/${device_path}"
tmp_dir="/tmp/surface_fw_extract"
msi_file="${tmp_dir}/SurfaceLaptop7_ARM_Win11.msi"
search_path="${tmp_dir}/SurfaceUpdate"

# Firmware files to extract
fw_files=(
    "adsp_dtbs.elf"
    "adspr.jsn"
    "adsps.jsn"
    "adspua.jsn"
    "battmgr.jsn"
    "cdsp_dtbs.elf"
    "cdspr.jsn"
    "qcadsp8380.mbn"
    "qccdsp8380.mbn"
    "qcdxkmsuc8380.mbn"
)

# Microsoft URL
url="https://download.microsoft.com/download/0/a/7/0a7d6bec-d3d8-4508-a8a0-0cbdb4d2119c/SurfaceLaptop7_ARM_Win11_26100_25.013.35106.0.msi"

# Create necessary directories
mkdir -p "${tmp_dir}" "${firmware_dir}"

# Download the MSI file
echo "Downloading firmware MSI..."
wget -q -O "${msi_file}" "${url}"

# Extract MSI contents
echo "Extracting MSI..."
msiextract -C "${tmp_dir}" "${msi_file}"

# Ensure extraction was successful
if [[ ! -d "${search_path}" ]]; then
    echo "Error: Extraction failed or missing ${search_path}"
    exit 1
fi

# Copy firmware files
echo "Copying firmware files..."
for f_path in "${fw_files[@]}"; do
    echo -e "\tSearching for ${f_path}..."
    fw_path=$(find "${search_path}" -type f -name "${f_path}" -print | head -n 1)

    if [[ -n "${fw_path}" ]]; then
        cp -v "${fw_path}" "${firmware_dir}/"
    else
        echo "Warning: ${f_path} not found!"
    fi
done

# Set correct permissions
chmod -R 0644 "${firmware_dir}"

echo "Firmware update complete!"
