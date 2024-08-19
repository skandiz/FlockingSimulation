import pandas as pd
import numpy as np
from tqdm import tqdm

import matplotlib.pyplot as plt
import matplotlib.animation
from mpl_toolkits.mplot3d import Axes3D
plt.rcParams['figure.figsize'] = (9, 6)
writervideo = matplotlib.animation.FFMpegWriter(fps=60)

configurations = 15

for k in tqdm(range(configurations)):
    data = pd.read_csv(f'Processed_data{k}.csv')

    fig = plt.figure()
    anim_running = True

    def onClick(event):
        global anim_running
        if anim_running:
            ani.event_source.stop()
            anim_running = False
        else:
            ani.event_source.start()
            anim_running = True

    def update_graph(frame):
        df = data.loc[frame*1000:frame*1000 + 1000 -1, ['x', 'y', 'z', 'color']]
        graph._offsets3d = (df.x, df.y, df.z)
        graph.set_facecolor(df.color)
        title.set_text('3D Test, time={}'.format(frame))

    ax = fig.add_subplot(111, projection='3d')
    ax.set_xlim3d([0, 1600])
    ax.set_ylim3d([0, 1600])
    ax.set_zlim3d([0, 1600])
    title = ax.set_title('3D Test')

    df = data.loc[0:999, ['x', 'y', 'z', 'color']]

    graph = ax.scatter(df.x, df.y, df.z, s=30, ec = "w", facecolor = df.color)

    fig.canvas.mpl_connect('button_press_event', onClick)
    ani = matplotlib.animation.FuncAnimation(fig, update_graph, 3600, interval = 1000/60, blit=False)


    ani.save(f'configuration{k}.mp4', writer=writervideo)

