import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.mixture import GaussianMixture
from scipy.stats import weibull_min
from scipy.optimize import curve_fit

# ----------------------------------------------------------------------
# 1. PDF + GMM DECONVOLUTION
# ----------------------------------------------------------------------
def plot_pdf_with_deconvolution_on_axis(data, column, n_components, ax):

    # Extract valid numeric values
    arr = data[column].dropna().values

    # ---------------- SAFETY CHECK (critical) ----------------
    if len(arr) < 2:
        ax.text(
            0.5, 0.5,
            f"Not enough data for GMM ({len(arr)} point)",
            ha="center", va="center",
            fontsize=14, transform=ax.transAxes
        )
        ax.set_xlabel(column)
        ax.set_ylabel("Density")
        return ax
    # ---------------------------------------------------------

    # Histogram
    sns.histplot(arr, bins=30, stat="density", color="lightgray",
                 edgecolor="black", ax=ax)

    # Fit GMM safely
    gmm = GaussianMixture(n_components=n_components, random_state=0)
    gmm.fit(arr.reshape(-1, 1))

    # Evaluation grid
    x = np.linspace(arr.min(), arr.max(), 1000).reshape(-1, 1)
    logprob = gmm.score_samples(x)
    pdf_total = np.exp(logprob)
    responsibilities = gmm.predict_proba(x)

    # Plot components
    for i in range(n_components):
        ax.plot(x, responsibilities[:, i] * pdf_total, label=f"Component {i+1}")

    ax.plot(x, pdf_total, "-k", label="GMM Total")

    ax.set_title(f"PDF + GMM Deconvolution — {column}")
    ax.set_xlabel(column)
    ax.set_ylabel("Density")
    ax.legend()

    return ax

# ----------------------------------------------------------------------
# 2. EMPIRICAL CDF + WEIBULL MIXTURE FIT
# ----------------------------------------------------------------------
def plot_cdf_with_weibull_fit_on_axis(data, column, ax):
    """
    Plot the empirical CDF and Weibull mixture fit.

    Parameters
    ----------
    data : DataFrame
        Input dataset.
    column : str
        Column to analyze.
    ax : matplotlib.axes.Axes
        Axis to plot on.
    """

    # Weibull mixture: each component has shape, scale, weight
    def weibull_mixture(x, *params):
        n = len(params) // 3
        cdf_sum = np.zeros_like(x, dtype=float)
        for i in range(n):
            shape = params[i * 3]
            scale = params[i * 3 + 1]
            weight = params[i * 3 + 2]
            cdf_sum += weight * weibull_min.cdf(x, shape, scale=scale)
        return cdf_sum

    # Empirical CDF
    sorted_values = np.sort(data[column].dropna())
    cdf = np.arange(1, len(sorted_values) + 1) / len(sorted_values)

    ax.step(sorted_values, cdf, where="post", label="Empirical CDF", color="blue")

    # Fit mixture (2 components default)
    x_fit = np.linspace(sorted_values.min(), sorted_values.max(), 1000)
    initial = [1.5, 2.0, 0.5, 3.0, 5.0, 0.5]  # [shape1, scale1, weight1, shape2...]

    try:
        popt, _ = curve_fit(weibull_mixture, sorted_values, cdf, p0=initial)
        mixture_cdf = weibull_mixture(x_fit, *popt)

        ax.plot(x_fit, mixture_cdf, "r-", label="Weibull Mixture Fit")

        # Debug parameters
        n_comp = len(popt) // 3
        for i in range(n_comp):
            print(
                f"Weibull Component {i+1}: "
                f"Shape={popt[i*3]:.3f}, "
                f"Scale={popt[i*3+1]:.3f}, "
                f"Weight={popt[i*3+2]:.3f}"
            )

    except Exception as e:
        print(f"⚠ Weibull mixture fit failed: {e}")

    ax.set_title(f"CDF + Weibull Mixture — {column}")
    ax.set_xlabel(column)
    ax.set_ylabel("CDF")
    ax.legend()


# ----------------------------------------------------------------------
# 3. CLUSTER SCATTER PLOTS
# ----------------------------------------------------------------------
def plot_clustered_data(
    data, xdata, ydata, huedata, colors, result_dir,
    xDim=10, yDim=6,
    title="KMeans Clustering (H vs E)",
    xlabel="Hardness (GPa)",
    ylabel="Modulus (GPa)"
):
    """
    Scatter plot of clustered mechanical properties.

    Parameters
    ----------
    data : DataFrame
    xdata, ydata : str
        Column names for x and y axes.
    huedata : str
        Column for cluster labels.
    colors : list or dict
        Cluster color palette.
    result_dir : Path
        Output directory.
    """

    if colors is None:
        colors = sns.color_palette("tab10", len(data[huedata].unique()))

    plt.figure(figsize=(xDim, yDim))
    sns.scatterplot(
        data=data,
        x=xdata,
        y=ydata,
        hue=huedata,
        palette=colors
    )

    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.legend(title="Cluster", bbox_to_anchor=(1.05, 1), loc="upper left")

    out = result_dir / (title.replace(" ", "_") + ".png")
    plt.savefig(out, bbox_inches="tight", dpi=300)
    print(f"📊 Clustered scatter saved → {out}")

    plt.close()


# ----------------------------------------------------------------------
# 4. CONTINUOUS SPATIAL MAP (TRI-CONTOURF)
# ----------------------------------------------------------------------
def plot_map(
    x, y, z,
    title, xlabel, ylabel,
    logScale, ax,
    cmap="viridis",
    save_path=None,
    vmin=None, vmax=None,
    fontsize=28
):
    """
    SAFE continuous contour map for arbitrary (x, y, z) values.
    Prevents triangulation crashes when points are insufficient.
    """

    import numpy as np
    import matplotlib.pyplot as plt

    # Convert to numpy and drop invalids
    x = np.asarray(x, float)
    y = np.asarray(y, float)
    z = np.asarray(z, float)

    mask = np.isfinite(x) & np.isfinite(y) & np.isfinite(z)
    x, y, z = x[mask], y[mask], z[mask]

    # ---- SAFETY CHECK : prevent tricontourf crash ----
    if (
        len(x) < 3
        or len(np.unique(x)) < 2
        or len(np.unique(y)) < 2
    ):
        ax.text(
            0.5, 0.5,
            "Insufficient data for contour map",
            ha="center", va="center",
            fontsize=fontsize - 6,
            transform=ax.transAxes
        )
        ax.set_xlabel(xlabel, fontsize=fontsize)
        ax.set_ylabel(ylabel, fontsize=fontsize)
        ax.set_aspect("equal")
        return ax
    # ---------------------------------------------------

    # Log scaling
    if logScale:
        with np.errstate(divide="ignore"):
            z = np.log10(z.clip(min=1e-12))
        title = title + " (log10)"

    # Actual tricontourf plot
    contour = ax.tricontourf(
        x, y, z,
        levels=14,
        cmap=cmap,
        vmin=vmin,
        vmax=vmax
    )
    cbar = plt.colorbar(contour, ax=ax)
    cbar.ax.tick_params(labelsize=fontsize - 4)

    ax.set_xlabel(xlabel, fontsize=fontsize)
    ax.set_ylabel(ylabel, fontsize=fontsize)
    ax.tick_params(axis="both", labelsize=fontsize - 4)
    ax.set_aspect("equal")

    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches="tight")
        print(f"📊 Map saved → {save_path}")

    return ax

# ----------------------------------------------------------------------
# 5. PIXELIZED MAP (DISCRETE CLUSTER MAP)
# ----------------------------------------------------------------------
def plot_pixel_map(
    x,
    y,
    z,
    title="",
    xlabel="X",
    ylabel="Y",
    xDim=4,
    yDim=2,
    cluster_colors=None,
    save_path=None,
):
    """
    TRUE PIXELIZED MAP (square pixels):
        • builds index grid from X,Y
        • produces one pixel per indentation point
        • square pixels regardless of physical spacing
        • works for numeric & categorical z values
    """

    import numpy as np
    import pandas as pd
    import matplotlib.pyplot as plt
    from matplotlib.colors import ListedColormap

    # Convert arrays
    x = np.asarray(x)
    y = np.asarray(y)
    z = np.asarray(z)

    # Handle phase/category labels → integers
    if z.dtype.kind in {"U", "S", "O"}:
        categories = sorted(pd.unique(z))
        cat_to_int = {c: i for i, c in enumerate(categories)}
        z_int = np.array([cat_to_int[v] for v in z])
    else:
        categories = None
        z_int = z.astype(float)

    # --------------------------------------------
    # 1) Build index grid (regular integer spacing)
    # --------------------------------------------
    xs = np.sort(np.unique(x))
    ys = np.sort(np.unique(y))

    nx = len(xs)
    ny = len(ys)

    # Create empty grid
    grid = np.full((ny, nx), np.nan, dtype=float)

    # Map coordinates → indices
    x_to_idx = {v: i for i, v in enumerate(xs)}
    y_to_idx = {v: i for i, v in enumerate(ys)}

    # Fill grid
    for xi, yi, zi in zip(x, y, z_int):
        grid[y_to_idx[yi], x_to_idx[xi]] = zi

    # Flip vertically so Y increases upward
    grid = np.flipud(grid)

    # --------------------------------------------
    # 2) Colormap
    # --------------------------------------------
    if cluster_colors is None:
        # auto discrete colormap
        n_colors = int(np.nanmax(z_int)) + 1
        base = plt.get_cmap("viridis")
        cmap = ListedColormap(base(np.linspace(0, 1, n_colors)))
    else:
        cmap = ListedColormap(cluster_colors)

    # --------------------------------------------
    # 3) Plot with imshow (perfect square pixels)
    # --------------------------------------------
    plt.figure(figsize=(xDim, yDim))

    plt.imshow(
        grid,
        cmap=cmap,
        interpolation="nearest",
        aspect="equal"   # <-- THE KEY FOR SQUARE PIXELS
    )

    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    if title:
        plt.title(title)

    plt.tight_layout()

    if save_path is not None:
        plt.savefig(save_path, dpi=300)
        print(f"📊 Pixel map saved → {save_path}")

    plt.close()
