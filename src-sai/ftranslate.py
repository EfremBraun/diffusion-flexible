"""
This program is designed to convert from a Tinker .xyz or .arc file 
to a LAMMPS trajectory (.traj) file. It will need to be run with an
accompanying ID files which contain the "time step" at each interval 
and the ids associated with every atom.

create_ben.py creates such a template for benzene molecules, however
only for the Hydrogens(H) in the system.

To create the LAMMPS file run as the following:-----

python ftranslate.py tinker_file IDS_file

"""

import sys
import os
import numpy as np

name = sys.argv[1]

# Execute this for an idea on how the IDs template should be formatted
if name == 'template':
	#print('\n# HERE IS THE INPUT TEMPLATE NEEDED\n')
	print('TIMESTEP: Value of Timestep')
	print('ATOM-ID		MOLECULE-ID')
	print('   1	    	   1 ')
	print('   2        	   1 ')
	print('   3        	   1 ')
	print('   4        	   2 ')
	print('   5        	   2 ')
	print('   6        	   2 ')
	print('\n# AND SO FORTH\n')
	sys.exit()
else:
	ids = sys.argv[2]
	try:
		f_input = open(name,'r')
		f_ids = open(ids,'r')
	except:
		sys.exit('ERROR. Either TINKER file or ID file is not in the same directory. Please Try Again.')


# This is creating file names for the output files for LAMMPS and corrfunc 
f_name = os.path.basename(name)
out_name = os.path.splitext(f_name)

out_file = open(out_name[0]+'_'+out_name[1][1:]+'.traj','w')
msd_out = open(out_name[0]+'_msd.dat','w')


# Parsing data from IDs file. This will read in the ids and the timestep
id_line = f_ids.readline()
sp_idline = id_line.split()
time_step = float(sp_idline[1])
act_time = time_step

id_line = f_ids.readline() # readline is called to skip lines until it is able to access the atom ids
id_line = f_ids.readline()


# writes atom ids to a dictionary
mol_dict = {}
while id_line != '':
	id_split = id_line.split()
	mol_dict[id_split[0]] = id_split[1]
	id_line = f_ids.readline()


# Reads in first line from Tinker file	
line = f_input.readline()
sp_line = line.split()
n_atms = int(sp_line[0]) # Number of atoms in input file


# Arrays of positions of atoms
x_old = []
y_old = []
z_old = []

x_cur = []
y_cur = []
z_cur = []

ixs = []
iys = []
izs = []

ixchck = []
iychck = []
izchck = []


# Corrfunc will skip the first 3 lines
msd_out.write("Line 1\n")
msd_out.write("Line 2\n")
msd_out.write("Line 3\n")


# Reads in the positions of the atoms in the Tinker file
while line != '':
	out_file.write('ITEM: TIMESTEP\n')
	out_file.write(str(act_time)+'\n')

	# header for MSD file.
	msd_out.write(str(act_time) + '      ' + str(n_atms) + '\n')
	
	# increments header 
	act_time += time_step	

	out_file.write('ITEM: NUMBER OF ATOMS\n')
	out_file.write(str(n_atms)+'\n')
	
	line = f_input.readline()
	sp_line = line.split()

	# boundaries of the box
	xbnd = sp_line[0]
	ybnd = sp_line[1]
	zbnd = sp_line[2]

	# Info header for LAMMPS output
	out_file.write('ITEM: BOX BOUNDS -- -- --\n')
	out_file.write('0 ' + xbnd +'\n')
	out_file.write('0 ' + ybnd +'\n')
	out_file.write('0 ' + zbnd +'\n')
	out_file.write('ITEM: ATOMS id mol type x y z ix iy iz\n')
	
	# every 6th counter
	COM_6 = 0

	# Averages for "Center of Mass"
	xave = []	
	yave = []
	zave = []
        
	for i in range(n_atms):
                atm_line = f_input.readline()
                sp_out = atm_line.split()

		mol_id = mol_dict[sp_out[0]]
		xm = float(sp_out[2])
		ym = float(sp_out[3])
		zm = float(sp_out[4])
		
		# Determines if atom has crossed periodic length
		if len(x_old) != n_atms:

			x_old.append(xm)
			y_old.append(ym)
			z_old.append(zm)
			
			ixs.append(0)
			iys.append(0)
			izs.append(0)
		else:
			xr = xm - x_old[i]
			if xr > float(xbnd)/2:
				ixs[i] -= 1
			elif xr < -float(xbnd)/2:
				ixs[i] += 1
			x_old[i] = xm

			yr = ym - y_old[i]
			if yr > float(ybnd)/2:
				iys[i] -= 1
			elif yr < -float(ybnd)/2:
				iys[i] += 1
			y_old[i] = ym
			
			zr = zm - z_old[i]
			if zr > float(zbnd)/2:
				izs[i] -= 1
			elif zr < -float(zbnd)/2:
				izs[i] += 1 
			z_old[i] = zm		
		
		# Writing out to the LAMMPS output			
		out_file.write(sp_out[0]+' '+mol_id+' '+'1'+' '+str(xm)+' '+str(ym)+' '+str(zm)+' '+str(ixs[i])+' '+str(iys[i])+' '+str(izs[i])+'\n')
		
		# Calculating the center of mass for 6 Hydrogens
		if (i/6 > COM_6 or (i==(n_atms-1))):
			pb = i-1
			if (i==(n_atms-1)):
				xave.append(xm)
				yave.append(ym)
				zave.append(zm)
				pb = i
			msd_out.write(str(sp_out[0]) + '       ' + str(np.mean(xave)) +'   ' + str(np.mean(yave)) + '     ' + str(np.mean(zave)) + '    ' + str(ixs[pb]) + ' ' + str(iys[pb]) + ' ' + str(izs[pb]) + '\n')
			COM_6 +=1
			xave = [xm]
			yave = [ym]
			zave = [zm]
		elif (i/6 <= COM_6):
			xave.append(xm)
			yave.append(ym)
			zave.append(zm)

       	line = f_input.readline()	


# Closing files
f_input.clost()
out_file.close()
msd_out.close()
