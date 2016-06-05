#!/bin/bash
# This is a BASH code to create directories for running a number of isotherms.

#Variables
component_flag=1 #set to 1 if you want the component to appear in the simulation title, 0 otherwise
component='schmpchr' #only used if component_flag is set to 1

echo "Creating directories for each framework"
cat structures_unitcells_heliumvoidfractions.txt | while read F; # read each structure
do
        f=( ${F} )
        echo "Framework: ${f[0]}"
	# if directories already exist, delete them and all of their contents
	if [ -d "${f[0]}" ]; then
		rm -rf ${f[0]}
		fi
	mkdir ${f[0]}
	cd ${f[0]}

	cat ../temperatures.txt | while read T;
	do
		mkdir Isotherm${T}K # make a directory for this temperature
		cd Isotherm${T}K # go inside temperature directory

		cat ../../pressures.txt | while read P;
		do
			mkdir Pressure$P # make a directory for each pressure
		        cd Pressure$P
                        cp ../../../simulation.input .
                        cp ../../../run_raspa.sh .
                        cp ../../../benzene-rigid.def .
                        cp ../../../force_field.def .
                        cp ../../../force_field_mixing_rules.def .
                        cp ../../../pseudo_atoms.def .
	        	grep -rl " FrameworkName " simulation.input | xargs sed -i "s/^.*FrameworkName.*$/FrameworkName ${f[0]%.*}/g" simulation.input
                        grep -rl " UnitCells " simulation.input | xargs sed -i "s/^.*UnitCells.*$/UnitCells ${f[1]%*} ${f[2]%*} ${f[3]%*}/g" simulation.input
                        grep -rl " HeliumVoidFraction " simulation.input | xargs sed -i "s/^.*HeliumVoidFraction.*$/HeliumVoidFraction ${f[4]%*}/g" simulation.input
                        grep -rl " ExternalTemperature " simulation.input | xargs sed -i "s/^.*ExternalTemperature .*$/ExternalTemperature ${T%*}/g" simulation.input
                        grep -rl " ExternalPressure " simulation.input | xargs sed -i "s/^.*ExternalPressure .*$/ExternalPressure ${P%*}/g" simulation.input
                        if [ "$component_flag" = 0 ]
                        then
                            name=i${f[0]:0:3}${T}${P}
                        else
                            name=i${f[0]:0:3}${component}${T}${P}
                        fi
			qsub -N $name run_raspa.sh
                        cd ..
		done
		cd ..
	done
	cd ..
done

echo "Directories complete"
