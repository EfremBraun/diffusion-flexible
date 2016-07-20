"""
This program creates an ID file that is required as an input
for ftranslate.py (Tinker to LAMMPS). This only creates an input
for hydrogens in a BENZENE

Requires the number of benezene molecules and the timestep.
"""

import argparse

parser = argparse.ArgumentParser()

# Input Arguments
parser.add_argument('-n', '--num', type=int)
parser.add_argument('-t', '--time', type=str)

args = parser.parse_args()

out = open('benzene.ids','w')

cnt = 0

# Loop to create atom and molecule ids
if args.num and args.time:
	atms = args.num*6
	out.write('TIMESTEP: '+args.time+'\n')
	out.write('ATOM-ID         MOLECULE-ID\n')
	for i in range(atms):
		if ((i+1)/6 != cnt) or (i==atms):
			out.write(str(i+1)+'\t\t'+str(cnt+1)+'\n')
			cnt += 1
		else:
			out.write(str(i+1)+'\t\t'+str(cnt+1)+'\n')

# Closing output file
out.close()
