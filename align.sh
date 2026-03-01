#!/bin.bash
#SBATCH --mail-user=isacaste@iu.edu
#SBATCH --mail-type=BEGIN,FALI,END
#SBATCH --job-name=align
#SBATCH -o align.out
#SBATCH -e align.err
#SBATCH --nodes=2
#SBATCH --mem=16g
#SBATCH -p gpu
#SBATCH --ntasks-per-node=2
#SBATCH --gpus-per-node=1
#SBATCH --time=1-23:59:00
#SBATCH -A r00750

# load
