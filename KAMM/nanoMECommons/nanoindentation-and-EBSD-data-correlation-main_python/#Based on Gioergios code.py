#Based on Gioergios code

################################################################################################################
# Load libraries and path
################################################################################################################

# Load libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from PIL import Image
from sklearn.cluster import DBSCAN, KMeans
from sklearn.decomposition import PCA
from sklearn.manifold import TSNE
from sklearn.preprocessing import scale
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, confusion_matrix
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsClassifier
from sklearn.cluster import KMeans
from sklearn.neighbors import NearestNeighbors
from sklearn.tree import DecisionTreeClassifier
from sklearn.naive_bayes import GaussianNB
from sklearn.neural_network import MLPClassifier
from sklearn.metrics import silhouette_score
from sklearn.metrics import calinski_harabasz_score
from sklearn.metrics import davies_bouldin_score
import os
import time
import warnings
warnings.filterwarnings("ignore")

# Parallel computing
import multiprocessing as mp
num_cores = mp.cpu_count()
print(f"Number of available cores: {num_cores}")

# Path
mypath = r"C:\Users\dmercier\OneDrive - ANSYS, Inc\pythonRepo\nanoMECommons\nanoindentation-and-EBSD-data-correlation-main_python"
os.chdir(mypath)

################################################################################################################
# Functions to be used
################################################################################################################
# fix plot theme for ggplot to ensure uniformity
def plot_theme():
    import matplotlib.pyplot as plt
    plt.rcParams['figure.figsize'] = (12, 8)
    plt.rcParams['font.size'] = 16
    plt.rcParams['axes.titlesize'] = 16
    plt.rcParams['axes.labelsize'] = 16
    plt.rcParams['xtick.labelsize'] = 16
    plt.rcParams['ytick.labelsize'] = 16
    plt.rcParams['legend.fontsize'] = 16
    plt.rcParams['lines.linewidth'] = 2
    plt.rcParams['lines.markersize'] = 10

# do distance based correlation for allocating colorshades to specific colors
# Function to compare RGB values with specific colors - more generic colors (maybe pale colors will be used)
# I play with it - choose colors for kColours as centers
def get_color_category(R, G, B):
    # Define standard RGB values for each color category
    colors_data = {
        'color': ['green', 'blue', 'red', 'yellow', 'pink', 'cyan', 'white', 'black'],
        'R': [0.4666667, 0.3529412, 0.6705882, 0.7921569, 0.8470588, 0.4901961, 1, 0],
        'G': [0.8313725, 0.3490196, 0.2784314, 0.8196078, 0.4313725, 0.8313725, 1, 0],
        'B': [0.4392157, 0.7843137, 0.2470588, 0.4000000, 0.6352941, 0.8156863, 1, 0]
    }

    # Function to find the closest color category for each row
    def find_closest_color(r, g, b):
        abs_diff = np.abs(np.array([colors_data['R'], colors_data['G'], colors_data['B']]) - np.array([r, g, b])).sum(axis=0)
        closest_color = colors_data['color'][np.argmin(abs_diff)]
        return closest_color

    # Apply the function to each row of R, G, and B
    color_categories = [find_closest_color(r, g, b) for r, g, b in zip(R, G, B)]
    return color_categories

# for data imputation with knn method
def impute_knn(train_data, test_data, k=8):
    # Separate predictors and response variables in the training set
    X_train = train_data[['x', 'y']]
    y_train = train_data[['R', 'G', 'B']]

    # Separate predictors in the test set
    X_test = test_data[['x', 'y']]

    # Use k-NN model to predict R, G, and B values for the test set
    imputed_data = test_data[['x', 'y']].copy()
    neigh = NearestNeighbors(n_neighbors=k)
    neigh.fit(X_train)
    _, indices = neigh.kneighbors(X_test)

    for col in ['R', 'G', 'B']:
        imputed_data[col] = y_train.iloc[indices].mean(axis=1)[col]

    return imputed_data