TriDiMap
=========
This Matlab toolbox has been developed to plot and to analyze mechanical properties maps from nanomechanical results .

To get started with the TriDiMap toolbox, clone the repository, then run Matlab, and cd into the folder containing this README file.

You can start the launcher by typing "demo" at the Matlab command prompt.

Features
--------

The TriDiMap toolbox has been developed to plot, to map and to analyze (nano)indentation datasets.

With this Matlab toolbox, it is possible:
    * to create 2D/3D mechanical-property maps from regular grids and point maps from irregular XY measurements, with interpolation, smoothing and cropping for grid maps;
    * to recalculate hardness and reduced indentation modulus from load, depth and stiffness data using Oliver-Pharr or Loubet contact models;
    * to plot elastic modulus vs hardness values, define sectors and perform phase clustering;
    * to cluster phases using K-means or GMM with mechanical and optional KAMM features, and display phase and KAMM maps;
    * to embed standardized mechanical/KAMM features with ISOMAP before K-means clustering, and inspect or export the embedding;
    * to visualize joint 3D probability densities of phases in elastic-modulus/hardness space;
    * to plot hardness/modulus phase clusters against a selectable KAMM-family descriptor in 3D;
    * to plot and fit probability density functions and cumulative density functions;
    * to extract per-phase mechanical-property statistics (mean, extrema and standard deviations) and phase fractions;
    * to correlate mechanical and microstructural maps for image-correlation-based targeted indentation (ICBTI) analysis;
    * to segment SEM grayscale maps into three or four phases and compare them with E/H maps using phase fractions and per-phase agreement metrics;
    * to plot 4D mechanical-property maps from indentation depth slices.

License-free Python examples
----------------------------

The `KAMM clustering notebook <python/kamm_clustering.ipynb>`_ demonstrates
2D modulus/hardness maps -> neighbourhood mismatch -> K-means/GMM clustering,
without MATLAB, Streamlit or Granta. Install ``python/requirements.txt`` and
open the notebook with Jupyter. See `the KAMM workflow guide <docs/kamm.rst>`_
for input conventions, MATLAB GUI controls and limitations.

The `PDF deconvolution notebook <python/pdf_deconvolution.ipynb>`_ loads
Excel or CSV E/H measurements, keeps raw maps separate from interpolation
and smoothing, and plots empirical and Gaussian-mixture PDF/CDF curves.
It assigns candidate phases and plots raw/processed phase maps using
the same fitted mixture, with raw per-phase statistics and optional CSV
exports. Its default MTS flower dataset contains a steel matrix and
carbide inclusion; the two-component hardness fit labels candidate
steel/carbide populations. Legacy ``.xls`` summaries are read directly
with xlrd. The 25-by-25 serpentine grid follows the MATLAB convention,
but spacing and scan orientation must be confirmed because the summary
has no XY metadata. See the
`statistical analysis guide <docs/pdf_cdf.rst>`_ for conventions and limitations.

Matlab version
------------------
Developed with Matlab R2014a.

Author
----------
:Author: `David Mercier <david9684@gmail.com>`_ [1]

[1] `CRM Group, Avenue du Bois Saint-Jean 21, B27 – Quartier Polytech 4, 4000 Liège, Belgium <http://www.crmgroup.be/>`_

Reference papers
------------------

* `Mercier D. et al., "Mechanical characterization by nanoindentation of an electroplated nickel matrix composite coating" (2017). <https://dx.doi.org/10.1051/mattech/2017014>`_
* `Mercier D. et al., "Microstructural and mechanical characterization of electroplated nickel matrix composite coatings" (2018). <https://doi.org/10.1080/02670844.2018.1433270>`_
* `Mercier D. et al., "Mechanical properties mapping of cast bimetallic work roll shell material by nanoindentation" (2018). <https://doi.org/10.13140/RG.2.2.35449.16482/1>`_
* `Huyghes P. et al., "On the Effect of Q&P Processing on the Stretch-flange-formability of 0.2C Ultra-high Strength Steel Sheets" (2018). <https://doi.org/10.2355/isijinternational.ISIJINT-2018-121>`_
* `Kossman S. et al., "Mechanical characterization by multiscale instrumented indentation of highly heterogeneous materials for braking applications" (2018). <https://doi.org/10.1007/s10853-018-3158-7>`_

Keywords
---------
|matlab| toolbox; nanoindentation; indentation mapping; mechanical properties;
regular grid; irregular XY; 2D mapping; 3D mapping; 4D mapping; interpolation;
smoothing; contact mechanics; Oliver-Pharr; Loubet; elastic modulus; hardness;
E-H plot; phase clustering; K-means; Gaussian mixture model; ISOMAP; KAMM;
phase map; joint probability density; probability density function;
cumulative density function; multimodal Gaussian fit; deconvolution;
image correlation; ICBTI; microstructure correlation; multiphase binarization;
SEM image segmentation; grayscale thresholding; multilevel Otsu; phase agreement;
confusion matrix; intersection-over-union.

Contributors
-------------
- Pierre Huyghes (ULB, Bruxelles) and Antoine Hilhorst (UCL, Louvain-La-Neuve) contributed to the Matlab code.
- Franck Nozahic (OCAS, Zwijnaarde) contributed to the documentation.

Acknowledgements
-----------------
The author is grateful to `Dr. Jiri Nemecek <http://ksm.fsv.cvut.cz/~nemecek/?page=resume&lang=en>`_ from `Czech Technical University <https://www.cvut.cz/en>`_, Czech Republic (Prague)
and to Dr. Nicholas Randall from `Anton Paar <https://www.anton-paar.com>`_, for discussions and many advices about nanoindentation mapping.

The author is grateful to Jean-François Vanhumbeeck and Xavier Vanden Eynde (`CRM Group <www.crmgroup.be>`_, Belgium (Liège)), for fruitful discussion and co-authoring of reference papers.

The author is grateful to Debora Rosseel, Franck Nozahic and Mélanie Gauvin (`OCAS <http://www.ocas.be/>`_, Belgium (Zwijnaarde)), for providing example files and lots le fruitful feedbacks.

Screenshots
-------------
.. figure:: docs/_pictures/MTS_example1_25x25_H_GUI.gif
   :scale: 50 %
   :align: center
   
   *3D mapping of sample hardness obtained from indentation tests.*
