#!/bin/bash -l

#SBATCH --partition shared
#SBATCH --qos premium
#SBATCH -n 1
#SBATCH --job-name schmid-replicate-10molecperuc-rigid
#SBATCH --time 48:00:00
#SBATCH --mail-type ALL
#SBATCH --mail-user efrem.braun@gmail.com

cd $SLURM_SUBMIT_DIR

sbatch -d afterok:$SLURM_JOB_ID run_tinker-postprocess.sl

#bin=${HOME}/Dropbox/Research/software/src/tinker/bin-linux64
bin=/global/homes/e/ebraun/software/tinker/bin-linux64
output_key_file=MOFwithBenzene.key
benzene_molecules=10
mof_unitcells=1


# high temperature to distribute benzene evenly
echo inactive -$(expr $benzene_molecules \* 12 + 1) $(expr $benzene_molecules \* 12 + $mof_unitcells \* 424) >> $output_key_file # freeze MOF atoms
$bin/dynamic MOFwithBenzene 50000 1 0.1 2 1000.0 | tee MOFwithBenzene-1.log
head -n -1 $output_key_file > temp_key_file; mv temp_key_file $output_key_file # unfreeze MOF atoms
mv MOFwithBenzene.arc MOFwithBenzene-1.arc
cp MOFwithBenzene.dyn MOFwithBenzene-1.dyn
sed -i '/25.945700   25.945700  129.728500   90.000000   90.000000   90.000000/d' MOFwithBenzene-1.arc # clean up lines that VMD can't read

# put benzene to the run temperature before unfreezing MOF atoms to prevent guest benzene molecules from collapsing the MOF structure
echo inactive -$(expr $benzene_molecules \* 12 + 1) $(expr $benzene_molecules \* 12 + $mof_unitcells \* 424) >> $output_key_file # freeze MOF atoms
$bin/dynamic MOFwithBenzene 10000 1 0.1 2 300.0 | tee MOFwithBenzene-2.log
#head -n -1 $output_key_file > temp_key_file; mv temp_key_file $output_key_file # unfreeze MOF atoms
mv MOFwithBenzene.arc MOFwithBenzene-2.arc
cp MOFwithBenzene.dyn MOFwithBenzene-2.dyn
sed -i '/25.945700   25.945700  129.728500   90.000000   90.000000   90.000000/d' MOFwithBenzene-2.arc # clean up lines that VMD can't read

# equilibrate
$bin/dynamic MOFwithBenzene 500000 1 0.1 2 300.0 | tee MOFwithBenzene-3.log
mv MOFwithBenzene.arc MOFwithBenzene-3.arc
cp MOFwithBenzene.dyn MOFwithBenzene-3.dyn
sed -i '/25.945700   25.945700  129.728500   90.000000   90.000000   90.000000/d' MOFwithBenzene-3.arc # clean up lines that VMD can't read

# production
$bin/dynamic MOFwithBenzene 2500000 1 0.1 2 300.0 | tee MOFwithBenzene-4.log
mv MOFwithBenzene.arc MOFwithBenzene-4.arc
cp MOFwithBenzene.dyn MOFwithBenzene-4.dyn
sed -i '/25.945700   25.945700  129.728500   90.000000   90.000000   90.000000/d' MOFwithBenzene-4.arc # clean up lines that VMD can't read
