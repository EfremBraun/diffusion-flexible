import numpy as np
from scipy import optimize, stats
import matplotlib.pyplot as plt
from scipy.stats import itemfreq

filename = 'lattice_energies.txt'

a0_guess = 7.5
c0_guess = 7.5
show_starting_guess = True

# load data
a, c, E = np.loadtxt(filename, skiprows=1, usecols=(0,1,2), unpack=True)

# define functions
def energy_function_second_order(a, c, parameters):
    a0 = parameters[0]
    c0 = parameters[1]
    k = parameters[2]
    Maa = parameters[3]
    Mac = parameters[4]
    Mcc = parameters[5]

    zeroth_order = k
    second_order = Maa*(a-a0)**2 + Mac*(a-a0)*(c-c0)+ Mcc*(c-c0)**2
    return zeroth_order + second_order

def energy_function_third_order(a, c, parameters):
    a0 = parameters[0]
    c0 = parameters[1]
    k = parameters[2]
    Maa = parameters[3]
    Mac = parameters[4]
    Mcc = parameters[5]
    Gaaa = parameters[6]
    Gaac = parameters[7]
    Gacc = parameters[8]
    Gccc = parameters[9]

    zeroth_order = k
    second_order = Maa*(a-a0)**2 + Mac*(a-a0)*(c-c0)+ Mcc*(c-c0)**2
    third_order = Gaaa*(a-a0)**3 + Gaac*(a-a0)**2*(c-c0)+ Gacc*(a-a0)*(c-c0)**2 + Gccc*(c-c0)**3
    return zeroth_order + second_order + third_order

def energy_function_fourth_order(a, c, parameters):
    a0 = parameters[0]
    c0 = parameters[1]
    k = parameters[2]
    Maa = parameters[3]
    Mac = parameters[4]
    Mcc = parameters[5]
    Gaaa = parameters[6]
    Gaac = parameters[7]
    Gacc = parameters[8]
    Gccc = parameters[9]
    Haaaa = parameters[6]
    Haaac = parameters[7]
    Haacc = parameters[8]
    Haccc = parameters[9]
    Hcccc = parameters[9]

    zeroth_order = k
    second_order = Maa*(a-a0)**2 + Mac*(a-a0)*(c-c0)+ Mcc*(c-c0)**2
    third_order = Gaaa*(a-a0)**3 + Gaac*(a-a0)**2*(c-c0)+ Gacc*(a-a0)*(c-c0)**2 + Gccc*(c-c0)**3
    fourth_order = Haaaa*(a-a0)**4 + Haaac*(a-a0)**3*(c-c0) + Haacc*(a-a0)**2*(c-c0)**2 + Haccc*(a-a0)*(c-c0)**3 + Hcccc*(c-c0)**4
    return zeroth_order + second_order + third_order + fourth_order

def sum_squared_second_order (parameters, a, c, energy):
    err = sum((energy_function_second_order(a, c, parameters) - energy)**2)
    return err

def sum_squared_third_order (parameters, a, c, energy):
    err = sum((energy_function_third_order(a, c, parameters) - energy)**2)
    return err

def sum_squared_fourth_order (parameters, a, c, energy):
    err = sum((energy_function_fourth_order(a, c, parameters) - energy)**2)
    return err

# second order optimization
x0 = np.concatenate((np.array([a0_guess, c0_guess]), np.ones(4)))
res = optimize.minimize(sum_squared_second_order, x0, args = (a, c, E), method = 'Powell')
print 'Completed second order optimization'
print 'a0 is ' + str(res.x[0]) + ', c0 is ' + str(res.x[1]) + ', remaining parameters are ' + str(res.x[2:])
print res.message

# third order optimization
x0 = np.concatenate((res.x, np.ones(4)))
res = optimize.minimize(sum_squared_third_order, x0, args = (a, c, E), method = 'Powell')
print 'Completed third order optimization'
print 'a0 is ' + str(res.x[0]) + ', c0 is ' + str(res.x[1]) + ', remaining parameters are ' + str(res.x[2:])
print res.message

# fourth order optimization
x0 = np.concatenate((res.x, np.ones(5)))
res = optimize.minimize(sum_squared_fourth_order, x0, args = (a, c, E), method = 'Powell')
print 'Completed fourth order optimization'
print 'a0 is ' + str(res.x[0]) + ', c0 is ' + str(res.x[1]) + ', remaining parameters are ' + str(res.x[2:])
print res.message

# plots
A = np.linspace(min(a), max(a))
C = np.linspace(min(c), max(c))
A_grid,C_grid = np.meshgrid(A,C)
fitted_energies = energy_function_fourth_order(A_grid, C_grid, res.x)

plt.figure()
CS = plt.contour(A_grid, C_grid, fitted_energies, 10)
plt.scatter(a, c, c=E, s=40)
plt.plot(res.x[0], res.x[1], 'kx')
plt.annotate(s=str(round(res.x[0],3)) + ',' + str(round(res.x[1],3)), xy=(res.x[0], res.x[1]), xytext=(2,2), textcoords='offset points')
CB = plt.colorbar()
plt.xlabel(r'a ($\AA$)')
plt.ylabel(r'c ($\AA$)')
CB.set_label('Energy (hartree)')
plt.tight_layout(pad=0.1)
plt.savefig('lattice-energy-contour.png')

plt.figure()
plt.subplot(121)
c_uniques = itemfreq(c)[:,0]
c_counts = itemfreq(c)[:,1]
if show_starting_guess == True:
    c_values = c_uniques[c_counts>0]
else:
    c_values = c_uniques[c_counts>1]
for i,c_value in enumerate(c_values):
    plt.plot(a[c==c_value], E[c==c_value], 'o')
plt.gca().set_color_cycle(None)
for i,c_value in enumerate(c_values):
    a_values = np.linspace(min(a), max(a))
    secondplot = plt.plot(a_values, energy_function_fourth_order(a_values, c_value, res.x), '-')
plt.axvline(res.x[0], ls='--', c='k')
plt.xlabel(r'a ($\AA$)')
plt.ylabel('Energy (hartree)')
plt.legend(c_values, title=r'c ($\AA$)', labelspacing=0.1)

plt.subplot(122)
a_uniques = itemfreq(a)[:,0]
a_counts = itemfreq(a)[:,1]
if show_starting_guess == True:
    a_values = a_uniques[a_counts>0]
else:
    a_values = a_uniques[a_counts>1]
for i,a_value in enumerate(a_values):
    plt.plot(c[a==a_value], E[a==a_value], 'o')
plt.gca().set_color_cycle(None)
for i,a_value in enumerate(a_values):
    c_values = np.linspace(min(c), max(c))
    secondplot = plt.plot(c_values, energy_function_fourth_order(a_value, c_values, res.x), '-')
plt.axvline(res.x[1], ls='--', c='k')
plt.xlabel(r'c ($\AA$)')
plt.legend(a_values, title=r'a ($\AA$)', labelspacing=0.1)

plt.tight_layout(pad=0.1)
plt.savefig('lattice-energy-modelfits.png')
