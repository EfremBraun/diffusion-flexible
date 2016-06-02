#!/bin/bash -l

#SBATCH --partition shared
#SBATCH --qos premium
#SBATCH -n 8
#SBATCH --job-name schmid-replicate-10molecperuc-rigid
#SBATCH --time 02:00:00
#SBATCH --mail-type ALL
#SBATCH --mail-user efrem.braun@gmail.com

cd $SLURM_SUBMIT_DIR

#bin=${HOME}/Dropbox/Research/software/src/tinker/bin-linux64
bin=/global/homes/e/ebraun/software/tinker/bin-linux64
output_key_file=MOFwithBenzene.key
benzene_molecules=10
mof_unitcells=1


# get file of benzene hydrogen atoms
# remove MOF atoms
$bin/xyzedit <<EOF
MOFwithBenzene-4.arc
Schmid2007.prm
2
-$(expr $benzene_molecules \* 12 + 1) $(expr $benzene_molecules \* 12 + $mof_unitcells \* 424)
EOF
mv MOFwithBenzene-4.xyz MOFwithBenzene-4.arc.benH
# Remove benzene carbon atoms
$bin/xyzedit <<EOF
MOFwithBenzene-4.arc.benH
Schmid2007.prm
3
2
EOF
mv MOFwithBenzene-4.arc.xyz MOFwithBenzene-4.arc.benH

# get file of MOF hydrogen atoms
# remove benzene atoms
$bin/xyzedit <<EOF
MOFwithBenzene-4.arc
Schmid2007.prm
2
-1 $(expr $benzene_molecules \* 12)
EOF
mv MOFwithBenzene-4.xyz MOFwithBenzene-4.arc.mofH
# Remove MOF non-hydrogen atoms
$bin/xyzedit <<EOF
MOFwithBenzene-4.arc.mofH
Schmid2007.prm
3
2 165 166 167 168
EOF
mv MOFwithBenzene-4.arc.xyz MOFwithBenzene-4.arc.mofH
