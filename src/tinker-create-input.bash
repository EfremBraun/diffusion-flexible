#!/bin/bash

# This script creates a supercell MOF xyz file from a unit cell MOF xyz file.
# It then bonds the MOF atoms based on distance.
# It then places stacked guest molecules into the supercell, which need to be relaxed.


# inputs
bin=${HOME}/Dropbox/Research/software/src/tinker/bin-linux64
bin_mod=${HOME}/Dropbox/Research/software/src/tinker-mod/bin # modded to connect bonds with PBC
a_unitcells=1
b_unitcells=1
c_unitcells=1
benzene_molecules=10
output_xyz_file=MOFwithBenzene.xyz
output_key_file=${output_xyz_file%.xyz}.key
ff=Schmid

if [ $ff = BTW ]; then
  cube_len=25.9013
  param_file=mofBTWwithbenzeneMM3pointchargenopibonds
  input_xyz_file_MOF=input-MOF-5-BTW.xyz
  input_xyz_file_ben=input-benzene-MM3.xyz
  input_key_file=input.key
elif [ $ff = Schmid ]; then
  cube_len=25.9457
  param_file=Schmid2007
  input_xyz_file_MOF=input-MOF-5-schmid.xyz
  input_xyz_file_ben=input-benzene-MM3.xyz
  input_key_file=input.key
fi

# clean up old files
rm ${input_xyz_file_MOF}_*
rm ${input_xyz_file_ben}_*

# correct key file's axes
cat ${input_key_file} > ${output_key_file}
a_len=$(expr ${cube_len}*${a_unitcells} | bc)
b_len=$(expr ${cube_len}*${b_unitcells} | bc)
c_len=$(expr ${cube_len}*${c_unitcells} | bc)
sed -i "s/^.*a-axis.*/a-axis ${a_len}/" ${output_key_file}
sed -i "s/^.*b-axis.*/b-axis ${b_len}/" ${output_key_file}
sed -i "s/^.*c-axis.*/c-axis ${c_len}/" ${output_key_file}

# translate MOF
a_uc=0
while [ $a_uc -lt $a_unitcells ];
do
translate_x=$(expr ${cube_len}*${a_uc}| bc)
b_uc=0
while [ $b_uc -lt $b_unitcells ];
do
translate_y=$(expr ${cube_len}*${b_uc}| bc)
c_uc=0
while [ $c_uc -lt $c_unitcells ];
do
translate_z=$(expr ${cube_len}*${c_uc}| bc)
$bin_mod/xyzedit <<EOF
${input_xyz_file_MOF}
${param_file}
11
${translate_x} ${translate_y} ${translate_z}
EOF
((c_uc++))
done
((b_uc++))
done
((a_uc++))
done

# combine MOF files.
if [ $a_uc -gt 1 ] || [ $b_uc -gt 1 ] || [ $c_uc -gt 1 ]; then
a_uc=0
while [ $a_uc -lt $a_unitcells ];
do
b_uc=0
while [ $b_uc -lt $b_unitcells ];
do
c_uc=0
while [ $c_uc -lt $c_unitcells ];
do
iter_num=$((1 + ${c_uc} + ${b_uc} * ${c_unitcells} + ${a_uc} * ${b_unitcells} * ${c_unitcells}))
file1=${input_xyz_file_MOF}_$((${iter_num} + ${a_unitcells} * ${b_unitcells} * ${c_unitcells}))
file2=${input_xyz_file_MOF}_$((${iter_num} + 1))
$bin_mod/xyzedit <<EOF
${file1}
${param_file}
18
${file2}
EOF
((c_uc++))
done
((b_uc++))
done
((a_uc++))
done
rm ${input_xyz_file_MOF}_$((1 + ${iter_num} + ${a_unitcells} * ${b_unitcells} * ${c_unitcells})) # because last iteration was not necessary
fi

# translate MOF COM to origin
file=${input_xyz_file_MOF}_$((2 * ${a_unitcells} * ${b_unitcells} * ${c_unitcells}))
$bin_mod/xyzedit <<EOF
${file}
${param_file}
12
EOF

# connect MOF bonds. need to rename key file temporarily so that xyzedit finds it
cp ${output_key_file} tinker.key
file=${input_xyz_file_MOF}_$((2 * ${a_unitcells} * ${b_unitcells} * ${c_unitcells} + 1))
$bin_mod/xyzedit <<EOF
${file}
${param_file}
8
EOF
rm tinker.key

# delete second line of MOF file because xyzedit adds in a second line which messes up combining the MOF and benzene files
sed -i -e "2d" ${input_xyz_file_MOF}_$((2 * ${a_unitcells} * ${b_unitcells} * ${c_unitcells} + 2))

# translate benzene
benzene_molec=0
benzene_molecs_per_c_cage=$(($benzene_molecules / (4 * $a_unitcells * $b_unitcells) + 1))
a_cage=0
while [ $a_cage -lt $((2 * $a_unitcells)) ];
do
translate_x=$(expr ${cube_len}*${a_cage}| bc)
b_cage=0
while [ $b_cage -lt $((2 * $b_unitcells)) ];
do
translate_y=$(expr ${cube_len}*${b_cage}| bc)
c_counter=0
while [ $c_counter -lt $benzene_molecs_per_c_cage ];
do
translate_x=$(expr ${cube_len}*${a_cage}/2.0| bc -l)
translate_y=$(expr ${cube_len}*${b_cage}/2.0| bc -l)
translate_z=$(expr ${cube_len}*${c_unitcells}*${c_counter}/${benzene_molecs_per_c_cage}| bc -l)
$bin_mod/xyzedit <<EOF
${input_xyz_file_ben}
${param_file}
11
${translate_x} ${translate_y} ${translate_z}
EOF
((benzene_molec++))
if [ $benzene_molec -ge $benzene_molecules ]; then break 3; fi
((c_counter++))
done
((b_cage++))
done
((a_cage++))
done

# combine benzene files
benzene_molec=2
while [ $benzene_molec -le $benzene_molecules ];
do
file1=${input_xyz_file_ben}_$((${benzene_molec} + ${benzene_molecules} - 1))
file2=${input_xyz_file_ben}_${benzene_molec}
$bin_mod/xyzedit <<EOF
${file1}
${param_file}
18
${file2}
EOF
((benzene_molec++))
done

# translate benzene COM to origin
file=${input_xyz_file_ben}_$((2 * ${benzene_molecules}))
$bin_mod/xyzedit <<EOF
${file}
${param_file}
12
EOF

# get benzene molecules to fit properly in xy plane (Efrem, need to toy around with this)
file=${input_xyz_file_ben}_$((2 * ${benzene_molecules} + 1))
if [ $ff = BTW ]; then
translate_xy=$(expr ${cube_len}/4.0| bc -l)
$bin_mod/xyzedit <<EOF
${file}
${param_file}
11
${translate_xy} ${translate_xy} 0
EOF
elif [ $ff = Schmid ]; then
translate_xy=$(expr ${cube_len}/4.0| bc -l)
$bin_mod/xyzedit <<EOF
${file}
${param_file}
11
${translate_xy} ${translate_xy} 0
EOF
fi

# combine MOF file and benzene file
file1=${input_xyz_file_ben}_$((2 * ${benzene_molecules} + 2))
file2=${input_xyz_file_MOF}_$((2 * ${a_unitcells} * ${b_unitcells} * ${c_unitcells} + 2))
$bin_mod/xyzedit <<EOF
${file1}
${param_file}
18
${file2}
EOF

# rename final file
cp ${input_xyz_file_ben}_$((2 * ${benzene_molecules} + 3)) ${output_xyz_file}

# clean up old files
rm ${input_xyz_file_MOF}_*
rm ${input_xyz_file_ben}_*

# relax system (only benzene molecules) so that benzene molecules aren't overlapping
echo inactive -$(expr $benzene_molecules \* 12 + 1) $(expr $benzene_molecules \* 12 + $a_unitcells \* $b_unitcells \* $c_unitcells \* 424) >> $output_key_file
$bin/minimize MOFwithBenzene 10
head -n -1 $output_key_file > temp_key_file; mv temp_key_file $output_key_file
