"""
Similar to plot_msd.py where it plots msd and determines the
diffusion coefficient 
"""

import numpy as np
import matplotlib.pyplot as plt
import argparse
from scipy import stats

parser = argparse.ArgumentParser(description="""
		plots msd and time and determines cofficient
		""")

parser.add_argument('-f','--file',
			type = str,
			default = 'msd_0.txt')
 
parser.add_argument('-bmin', '--ballistic_min',
                    type = float,
                    help = 'values equal to and above this will \
                    be included')

parser.add_argument('-bmax', '--ballistic_max',
                    type = float,
                    help = 'values less than (not including) this will \
                    be included')

parser.add_argument('-dmin', '--diffusive_min',
                    type = float,
                    help = 'values equal to and above this will \
                    be included')

parser.add_argument('-dmax', '--diffusive_max',
                    type = float,
                    help = 'values less than (not including) this will \
                    be included')

parser.add_argument('-t','--temperature',
			type = str,
			help = 'the temperature at which the simulation \
			was conducted in')
parser.add_argument('-tn','--test_name',
			type = str,
			help = 'the type of simulation')

# USE this command to print out the diffusion coefficients
parser.add_argument('-p','--printf',
			help = 'prints out a text file containing the diffusion \
				coefficient')

args = parser.parse_args()

time = np.loadtxt(args.file, skiprows=2, usecols=(0,))
msd = np.loadtxt(args.file, skiprows=2, usecols=(4,))
log_time = np.log10(time)
log_msd = np.log10(msd)

fig = plt.figure(1)
ax1 = plt.subplot(111)
ax1.set_xlabel('Time')
ax1.set_ylabel('MSD')
ax1.set_xscale('log')
ax1.set_yscale('log')
ax1.plot(time,msd,'o')

if args.temperature and args.test_name:
	ax1.set_title(args.test_name + ' ' + args.temperature)
else:
	ax1.set_title(args.test_name)

near_m = 0 # slope at near times
far_m = 0 # slope at far times

if args.ballistic_min and args.ballistic_max:
    ar_b, indices_b = np.unique(np.clip(time, args.ballistic_min,
        args.ballistic_max), return_index=True)
    indices_b = np.insert(indices_b[1:], 0, indices_b[1]-1)[0:-1]
    x = log_time[indices_b]
    y = log_msd[indices_b]
    slope, intercept, r_value, p_value, std_err = stats.linregress(x,y)
    near_m = slope
    ax1.plot(10**log_time, 10**intercept * (10**log_time)**slope)
    ax1.plot(10**x, 10**intercept * (10**x)**slope)
    ax1.text(10**x[0]*2, 10**y[0]*5, 'y={:.3g}*x+{:.3g}'.format(slope, intercept))

if args.diffusive_min and args.diffusive_max:
    ar_d, indices_d = np.unique(np.clip(time, args.diffusive_min,
        args.diffusive_max), return_index=True)
    indices_d = np.insert(indices_d[1:], 0, indices_d[1]-1)[0:-1]
    x = log_time[indices_d]
    y = log_msd[indices_d]
    linx = time[indices_d]
    liny = msd[indices_d]
    slope, intercept, r_value, p_value, std_err = stats.linregress(x,y)
    linslope, linintercept, linr_value, linp_value, linstd_err = stats.linregress(linx,liny)
    far_m = linslope
    ax1.plot(10**log_time, 10**intercept * (10**log_time)**slope)
    ax1.plot(10**x, 10**intercept * (10**x)**slope)
    ax1.text(10**x[0]/2, 10**y[0]/5, 'y={:.3g}*x+{:.3g}'.format(slope, intercept))

# Need to use both the test name and temperature argument, otherwise modify
# Diffusion coefficient = far slope / 6
if args.printf:
	out = open('diffuse_coff.txt','w')
	out.write('Diffusion Coefficient for '+args.test_name+' '+args.temperature+'\n')
	out.write(str(far_m/6))
	out.close()

fig.savefig(args.temperature+'.png')

