
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

# ORDER, POLARIZATION, MEAN DISTANCE BETWEEN AGENTS AND MEAN PERCEIVED AGENTS
@njit(nogil=True)
def get_observables1(num_iterations, progress_proxy, N, position, velocity, perceivedAgents, framesList): 
	order = np.zeros(len(framesList))
	polarization = np.zeros(len(framesList))

	meanDistance = np.zeros(len(framesList))

	meanPerceivedAgents = np.zeros((len(framesList), 2))

	for frame in range(len(framesList)): 

		summ = np.zeros(3)
		d = np.zeros(int(N*(N-1)/2))
		count = 0

		for i in prange(N): 
			normalizedVelocity = velocity[i + frame*N, :] / (np.linalg.norm(velocity[i + frame*N, :]))
			summ += normalizedVelocity

			for j in prange(i+1, N):
				d[count] = np.sqrt( (position[i+frame*N, 0] - position[j+frame*N, 0])**2 
								   +(position[i+frame*N, 1] - position[j+frame*N, 1])**2 
								   +(position[i+frame*N, 2] - position[j+frame*N, 2])**2 )
				count +=1

		
		order[frame] = np.linalg.norm(summ)/N
		polarization[frame] = np.std(velocity[frame*N:(frame+1)*N])

		meanDistance[frame] = np.mean(d)

		meanPerceivedAgents[frame, 0] = np.mean(perceivedAgents[frame*N:(frame+1)*N, 0])
		meanPerceivedAgents[frame, 1] = np.mean(perceivedAgents[frame*N:(frame+1)*N, 1])

		progress_proxy.update(1)

	return order, polarization, meanDistance, meanPerceivedAgents

#From https://stackoverflow.com/a/6802723/2460137 , simply decorated the functions with numba
@njit(nogil=True)
def rotation_matrix(axis, theta):
	"""
	Return the rotation matrix associated with counterclockwise rotation about
	the given axis by theta radians.
	"""
	axis = np.asarray(axis)
	axis = axis / math.sqrt(np.dot(axis, axis))
	a = math.cos(theta / 2.0)
	b, c, d = -axis * math.sin(theta / 2.0)
	aa, bb, cc, dd = a * a, b * b, c * c, d * d
	bc, ad, ac, ab, bd, cd = b * c, a * d, a * c, a * b, b * d, c * d
	return np.array([[aa + bb - cc - dd, 2 * (bc + ad), 2 * (bd - ac)],
					 [2 * (bc - ad), aa + cc - bb - dd, 2 * (cd + ab)],
					 [2 * (bd + ac), 2 * (cd - ab), aa + dd - bb - cc]])


@njit(nogil=True)
def angleBetween(dist, v):
	theta = np.arccos(v[2]/np.linalg.norm(v))
	normal = np.cross(v/np.linalg.norm(v), [0, 0, 1])
	new_dist = np.dot(rotation_matrix(normal, theta), dist)
	p = np.arctan(np.linalg.norm(new_dist[:-1])/new_dist[2])
	a = np.arctan2(new_dist[1], new_dist[0])
	return p, a

def getAngles(X, V, number_of_neighbours):
	nbrs = NearestNeighbors(n_neighbors = number_of_neighbours + 1, algorithm = 'auto').fit(X)
	_, indices = nbrs.kneighbors(X)
	p = np.zeros((len(X), 3))
	a = np.zeros((len(X), 3))
	# get angular distribution of the first first, second and tenth nearest neighbours
	for i in range(len(X)):
		p[i, 0], a[i, 0] = angleBetween(X[indices[i, 1]] - X[i], V[i])
		p[i, 1], a[i, 1] = angleBetween(X[indices[i, 2]] - X[i], V[i])
		p[i, 2], a[i, 2] = angleBetween(X[indices[i, number_of_neighbours]] - X[i], V[i])
	return p, a

def getAngularDistribution(N, data, framesList, number_of_neighbours):
	phiList = np.zeros((len(framesList), N, 3))
	alphaList = np.zeros((len(framesList), N, 3))
	for frame in tqdm(range(len(framesList))): 
		X = data[frame*1000:(frame+1)*1000, :3]
		V = data[frame*1000:(frame+1)*1000, 3:6]
		p, a = getAngles(X, V, number_of_neighbours)
		phiList[frame] = p
		alphaList[frame]= a
	return phiList, alphaList



