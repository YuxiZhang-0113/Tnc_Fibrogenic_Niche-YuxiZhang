#!/bin/bash
source ~/.bashrc
eval "$(conda shell.bash hook)"

export PATH=/home/yyyuxi/software/cellranger_software/cellranger-8.0.1:$PATH

transcriptome_path="/home/yyyuxi/software/cellranger_software/refdata-gex-GRCm39-2024-A"

for sample in *_S1_L001_R1_001.fastq.gz; do
    sample_id=$(basename "$sample" _S1_L001_R1_001.fastq.gz)

    cellranger count --id="$sample_id" \
                     --transcriptome="$transcriptome_path" \
                     --fastqs=./ \
                     --sample="$sample_id" \
                     --create-bam=true \
                     --nosecondary \
                     --localcores=8

    fastq_files_to_delete=("${sample_id}"*.fastq.gz)
    for file in "${fastq_files_to_delete[@]}"; do
        echo "正在删除 $file..."
        rm "$file"
    done
done


process_folder() {
    local filepath="$1"

    if [ -z "$filepath" ]; then
        echo "Error: No filepath provided."
        return 1
    fi

    cd "$filepath" || { echo "Error: Cannot cd to $filepath"; return 1; }

    conda activate velo

    subfolder=$(find . -mindepth 1 -maxdepth 1 -type d)

    mv "$subfolder/outs" . || { echo "Error: Failed to move outs folder"; return 1; }

    rm -rf "$subfolder"

    local rmsk_gtf="/home/yyyuxi/software/cellranger_software/velocyto/rmsk_gtf/mmu_rmsk.gtf"
    local cellranger_gtf="/home/yyyuxi/software/cellranger_software/velocyto/gtf/mmu/genes.gtf"
    local cellranger_outDir="./"

    echo "cellranger output directory: $cellranger_outDir"

    velocyto run10x -m "$rmsk_gtf" "$cellranger_outDir" "$cellranger_gtf" || { echo "Error: velocyto run10x failed"; return 1; }

    cd outs || { echo "Error: Cannot cd to outs folder"; return 1; }

    find . -mindepth 1 -maxdepth 1 ! -name "filtered_feature_bc_matrix" ! -name "raw_feature_bc_matrix" -exec rm -rf {} \;

    echo "Processing completed for $filepath"
}


filepath=$(pwd)
process_folder "$filepath"

