import pandas as pd
import numpy as np
import networkx as nx 
from networkx.algorithms.community import greedy_modularity_communities
from tqdm import tqdm
import random
import joblib

@joblib.delayed
def clustering(frame, data, colors):
    colorList = []
    clusterList = []

    X = np.array(data.loc[frame*1000:(frame+1)*1000 - 1, ['x', 'y', 'z']])

    # create dictionary with positions of the agents
    dicts = {}
    for i in range(len(X)):
        dicts[i] = (X[i,0], X[i,1], X[i,2])

    # generate random geometric graph with cutoff distance = 50, chosen here equal to the radius of separation
    G = nx.random_geometric_graph(len(dicts), 50, dim=3, pos=dicts, p=2, seed=None)

    # obtain communities from greedy modularity maximization and resolution = .1 
    c = greedy_modularity_communities(G, resolution = .1)

    clust = np.zeros(len(X)).astype(np.int32)

    for i in range(len(c)):
        for j in list(c[i]):
            clust[j] = i
    
    # assign number and color to every agent, at every frame 
    for i in range(len(X)):
        clusterList.append(clust[i])
        colorList.append(colors[clust[i]])
    return colorList, clusterList, frame


def main():
    n_fames = 3600
    framesList = np.arange(0, n_fames, 1) 
    configurations = 15

    n = 5
    random.seed(5)
    colors = ["#"+''.join([random.choice('0123456789ABCDEF') for j in range(6)]) for i in range(n)]
    for i in range(1010-n):
        colors.append("#000000")
    
    for k in range(configurations):

        data = pd.read_csv(f"Flock1data{k}.csv", sep = ' ')

        parallel = joblib.Parallel(n_jobs = -2)
        result = parallel(
            clustering(frame, data, colors)
            for frame in tqdm( range(len(framesList)) )
        )
        
        list1 = [result[i][0] for i in range(n_fames)]
        list1 = [item for sublist in list1 for item in sublist]

        list2 = [result[i][1] for i in range(n_fames)]
        list2 = [item for sublist in list2 for item in sublist]

        list3 = [result[i][2] for i in range(n_fames)]

        dataNew = data.loc[:n_fames*1000-1, ['x','y','z','vx','vy','vz']]
        dataNew["cluster"] = list2
        dataNew["color"] = list1
        dataNew.columns = ['x', 'y', 'z','vx', 'vy', 'vz','cluster','color'] 
        dataNew.to_csv(f'Processed_data{k}.csv', index=False)
        print(f"End config {k}")

if __name__ == '__main__':
    main()





