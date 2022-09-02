import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

import math
import pandas as pd
import numpy as np
import time
import copy
import random

from numba import njit, prange
from numba_progress import ProgressBar

from tqdm import tqdm

from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
from sklearn.neighbors import NearestNeighbors

from scipy.stats import linregress
from scipy.spatial import ConvexHull

from kneed import KneeLocator

import networkx as nx 
from networkx.algorithms.community import greedy_modularity_communities

plt.rcParams['figure.figsize'] = (9, 6)

from functions import get_observables1, getAngularDistribution

######################################################################################################################################
#   					IMPORT DATA, SET NUMBER OF ELEMENTS AND FRAMES TO ANALYZE 
######################################################################################################################################

plotVerb = True
configurations = 15
N = 1000
framesList = np.arange(0, 3600, 1) 

dataList = []
nBoids = np.zeros(configurations, dtype=int)
noiseMultiplier = np.zeros(configurations)
alignMultiplier = np.zeros(configurations)
cohesionMultiplier = np.zeros(configurations)
separationMultiplier = np.zeros(configurations)

for k in range(configurations):
	dataList.append(pd.read_csv(f"Flock1data{k}.csv", sep = ' '))
	p = pd.read_csv(f"parameters{k}.csv", sep = ' ', header=None,  dtype=np.float32)
	p.columns = ["a", "b", "c", "d", "e"]
	nBoids[k] = int(p.a)
	noiseMultiplier[k] = np.round(p.b, 4)
	alignMultiplier[k] = np.round(p.c, 4)
	cohesionMultiplier[k] = np.round(p.d, 4)
	separationMultiplier[k] = np.round(p.e, 4)

parameters = pd.DataFrame()
parameters["num"] = nBoids
parameters["noise"] = noiseMultiplier
parameters["alignment"] = alignMultiplier
parameters["cohesion"] = cohesionMultiplier
parameters["separation"] = separationMultiplier
print(parameters)

print("End of import data")
print(f'\n')

######################################################################################################################################
#   						SET BINNING AND GET ISOTROPIC DENSITY
######################################################################################################################################

delta1 = np.pi/20.
delta2 = np.pi/10.
offset = 0.00000001

phi_bin = np.arange(-np.pi/2. , np.pi/2. + offset , delta1)
alpha_bin = np.arange(-np.pi , np.pi + offset, delta2)

p = np.random.uniform(low=-np.pi/2., high = np.pi/2. + offset, size=(100000,))
a = np.random.uniform(low=-np.pi, high = np.pi + offset, size=(100000,))
randomHist, _, _ = np.histogram2d(a, p, bins=[alpha_bin, phi_bin], density = True)

normalization = np.mean(randomHist)
print("Binning set and computation of isotropic normalization:", normalization)

######################################################################################################################################
#   								MAIN
######################################################################################################################################

meanDistance = np.zeros((configurations, len(framesList)))
meanPerceivedAgents = np.zeros((configurations, len(framesList), 2))
order = np.zeros((configurations, len(framesList)))
polarization = np.zeros((configurations, len(framesList)))
volume = np.zeros((configurations, len(framesList)))

number_of_neighbours = 10

first_neighbour_meanHist = []
second_neighbour_meanHist = []
last_neighbour_meanHist = []

for k in range(configurations):
	X = np.array(dataList[k].loc[:, ['x', 'y', 'z']])
	V = np.array(dataList[k].loc[:, ['vx', 'vy', 'vz']])

	data = np.array(dataList[k].loc[:, ['x', 'y', 'z', 'vx', 'vy', 'vz']])

	perceivedAgents = np.array(dataList[k].loc[:, ['n_c', 'n_a']])

	print(f'\n')
	print(f"Order, Polarization, Mean Distance and Mean Perceived Agents of configuration {k}:")
	with ProgressBar(total=len(framesList)) as progress:
		order[k], polarization[k], meanDistance[k], meanPerceivedAgents[k] = get_observables1(len(framesList), progress, N, X, V, perceivedAgents, framesList)
	

	print(f'\n')
	print(f"Volume of configuration {k}:")
	for frame in tqdm(range(len(framesList))):
		volume[k, frame] = ConvexHull(X[frame*N:(frame+1)*N]).volume


	print(f'\n')
	print(f"Angular Distribution of configuration {k}:")
	phiList1, alphaList1 = getAngularDistribution(N, data, framesList, number_of_neighbours)


	print(f'\n')
	print(f"Neighbours Mean Angular Distributuion of configuration {k}:")
	first_neighbour_histList = []
	second_neighbour_histList = []
	last_neighbour_histList = []
	for frame in tqdm(range(len(framesList))): 
	    hist, _, _ = np.histogram2d(alphaList1[frame, :, 0],
	                                 phiList1[frame, :, 0], bins=[alpha_bin, phi_bin], density=True)
	    first_neighbour_histList.append(hist)
	    
	    hist, _, _ = np.histogram2d(alphaList1[frame, :, 1],
	                                 phiList1[frame, :, 1], bins=[alpha_bin, phi_bin], density=True)
	    second_neighbour_histList.append(hist)
	    
	    hist, _, _ = np.histogram2d(alphaList1[frame, :, 2],
	                                 phiList1[frame, :, 2], bins=[alpha_bin, phi_bin], density=True)
	    last_neighbour_histList.append(hist)

	first_neighbour_meanHist.append(np.mean(first_neighbour_histList, axis=0))
	second_neighbour_meanHist.append(np.mean(second_neighbour_histList, axis=0))
	last_neighbour_meanHist.append(np.mean(last_neighbour_histList, axis=0))

######################################################################################################################################
#   								PLOT
######################################################################################################################################

# ISOTROPIC CASE DENSITY DISTRIBUTION
if plotVerb:
	fig, (ax) = plt.subplots(1, 1, figsize = (10, 3), subplot_kw = dict(projection = "mollweide"))
	graph = ax.pcolormesh(alpha_bin, phi_bin, randomHist.T/normalization, cmap = "RdYlGn", shading='auto', vmin=0.8, vmax=1.2)
	ax.set_xticks([])
	ax.set_yticks([])
	ax.grid(which='major', axis='both', color='k', linewidth=.2)
	fig.colorbar(graph)
	plt.title("Isotropic density")
	plt.show()

# MEAN PERCEIVED AGENTS PLOT - neglect first frame for the purpose of the plot
if plotVerb:
	fig = plt.figure(figsize=(10, 4))
	ax = fig.add_subplot(111)
	for k in range(configurations):
		if k == configurations-1:
			ax.plot(framesList[1:]/60, meanPerceivedAgents[k, 1:, 0], 'r-', linewidth = .5, label = "$n_c$")
			ax.plot(framesList[1:]/60, meanPerceivedAgents[k, 1:, 1], 'b-', linewidth = .5, label = "$n_a$")
		else:
			ax.plot(framesList[1:]/60, meanPerceivedAgents[k, 1:, 0], 'r-', linewidth = .5)
			ax.plot(framesList[1:]/60, meanPerceivedAgents[k, 1:, 1], 'b-', linewidth = .5)
		
	ax.set_xlabel("Time  [s]")
	ax.set_ylabel("Mean perceived agents")
	ax.legend()
	plt.grid()
	plt.show()

# ORDER POLARIZATION AND VOLUME PLOT
if plotVerb:
	for k in range(configurations):
		fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(9, 6), sharex=True)
		plt.suptitle(f"Configuration {k} with Noise {np.round(noiseMultiplier[k],3)}, Align {alignMultiplier[k]}, Cohesion {cohesionMultiplier[k]}, Separation {np.round(separationMultiplier[k],3)}")
		
		ax1.plot(framesList/60, order[k])
		ax2.plot(framesList/60, polarization[k])
		ax3.plot(framesList/60, volume[k])
		
		ax1.set_ylabel("Order")
		ax2.set_ylabel("Polarization")
		ax3.set_ylabel("Volume occupied")
		ax3.set_xlabel("Time [s]")

		ax1.grid()
		ax2.grid()
		ax3.grid()
		plt.tight_layout()
		plt.show()

# MEAN DISTANCE PLOT 
if plotVerb:
	for k in range(configurations):
		fig, (ax) = plt.subplots(1, 1, figsize = (10, 3))
		plt.title(f"Configuration {k}: Noise {np.round(noiseMultiplier[k],3)}, Align {alignMultiplier[k]}, Cohesion {cohesionMultiplier[k]}, Separation {np.round(separationMultiplier[k],3)}")
		ax.plot(framesList/60, meanDistance[k])
		ax.set_xlabel("Time [s]")
		ax.set_ylabel("Mean distance between agents")
		ax.grid()
		plt.show()

# MEAN ANGULAR DISTRIBUTION PLOT
if plotVerb:
	for k in range(configurations):

		fig, (ax, ax1, ax2) = plt.subplots(3, 1, figsize = (8, 6), subplot_kw = dict(projection = "mollweide"))
		graph = ax.pcolormesh(alpha_bin, phi_bin, first_neighbour_meanHist[k].T/normalization, cmap = "seismic", shading='auto', vmin = 0, vmax = 2)
		graph1 = ax1.pcolormesh(alpha_bin, phi_bin, second_neighbour_meanHist[k].T/normalization, cmap = "seismic", shading='auto', vmin = 0, vmax = 2)
		graph2 = ax2.pcolormesh(alpha_bin, phi_bin, last_neighbour_meanHist[k].T/normalization, cmap = "seismic", shading='auto', vmin = 0, vmax = 2)

		ax.set_xlabel("First neighbour")
		ax1.set_xlabel("Second neighbour")
		ax2.set_xlabel("Last neighbour")
		plt.suptitle(f"Configuration {k}: Noise {np.round(noiseMultiplier[k],3)}, Align {alignMultiplier[k]}, Cohesion {cohesionMultiplier[k]}, Separation {np.round(separationMultiplier[k],3)}")

		ax.set_xticks([])
		ax.set_yticks([])
		ax1.set_xticks([])
		ax1.set_yticks([])
		ax2.set_xticks([])
		ax2.set_yticks([])
		axlist = [ax, ax1, ax2]
		fig.colorbar(graph, ax=axlist)

		plt.show()


###################################################################################################
#   	  				WIP: FRACTAL DIMENSION 
##################################################################################################

# @njit(nogil=True)
# def get_correlationSum(positions): 
#     pairsCount = np.zeros((len(framesList), len(rList)))
#     for i in prange(len(framesList)):
#         for j in prange(N):
#             for k in prange(j+1, N):
#                 d = np.sqrt( (positions[j+framesList[i]*N, 0] - positions[k+framesList[i]*N, 0])**2 
#                             + (positions[j+framesList[i]*N, 1] - positions[k+framesList[i]*N, 1])**2 
#                             + (positions[j+framesList[i]*N, 2] - positions[k+framesList[i]*N, 2])**2 )
#                 for h in range(len(rList)):
#                     if d < rList[h]:
#                         pairsCount[i][h] += 1
#     return 2*pairsCount/(N*(N-1))
# 
# rStep = 10
# rList = np.arange(20, 80, rStep)
# 
# correlationSum = np.zeros((configurations, len(framesList), len(rList)))
# 
# for n in range(configurations): 
#     start = time.time()
#     data = dataList[n]
#     X = np.array(data.loc[:, ['x', 'y', 'z']])
#     correlationSum[n] = get_correlationSum(X)
# 
#     end = time.time()
#     print(f"Fractal Dimension Analysis configuration {n} completed in {end - start} seconds")
# 
# 
# k = 3
# if plotVerb:
#     fig = plt.figure(figsize=(9, 3))
#     plt.suptitle(f"Configuration {k} with Noise {noiseMultiplier[k]}, Align {alignMultiplier[k]}, Cohesion {cohesionMultiplier[k]}, Separation {separationMultiplier[k]}")
# 
#     for i in range(0, len(framesList), 1000):
#         model = linregress(np.log(rList), np.log(correlationSum[k][i]))
# 
#         fit = np.e **(model.slope*np.log(rList) + model.intercept) 
#         plt.loglog(rList, fit, label = f'frame {framesList[i]} fit')
#         plt.loglog(rList, correlationSum[k][i],'.-' ,label = f'frame {framesList[i]}')
#     plt.legend() 
#     plt.show()
# 
# 
# correlationDimensions = np.zeros((configurations, len(framesList)))
# for k in range(configurations):
#     for i in range(len(framesList)):
#         correlationDimensions[k][i] = linregress(np.log(fitRange), np.log(correlationSum[k][i])).slope




