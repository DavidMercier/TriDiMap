Getting started
================

.. include:: includes.rst

First of all, download the source code of the |matlab| toolbox.

`Source code is hosted at Github. <https://github.com/DavidMercier/TriDiMap>`_
  
How to use the GUI for indentation mapping?
####################################################

First of all a GUI is a Graphical User Interface.

* Run the following |matlab| script :

.. code-block:: matlab

   demo.m
   
* Answer 'y' or 'yes' (or press 'Enter') to add path to the |matlab| search paths, using this script:

.. code-block:: matlab

   path_management.m

* The following window opens:

.. figure:: ./_pictures/GUI_Main_Window.png
   :scale: 40 %
   :align: center
   
   *Screenshot of the main window of the TriDiMap toolbox.*

* Set your type of equipment and units for length and mechanical property.

* Set the number of indents along the X and the Y directions.

* Import your (nano)indentation results, by clicking on the button 'Select file'.
  `Click here to have more details about valid format of data.
  <http://tridimap.readthedocs.org/en/latest/examples.html>`_

* Hardness map is plotted by default.

* It is possible `to modify (to crop, to smooth, to set other colorbar...) <https://tridimap.readthedocs.io/en/latest/map_options.html>`_ this map and to plot other 2D or 3D maps, and to obtain the statistical distribution of mechanical properties:

  - `2D map <https://tridimap.readthedocs.io/en/latest/mapping.html>`_
  
  - `3D / 4D map <https://tridimap.readthedocs.io/en/latest/tomography.html>`_
  
  - `Statistical analysis <https://tridimap.readthedocs.io/en/latest/pdf_cdf.html>`_
  
  - `Hardness vs Elastic modulus map <https://tridimap.readthedocs.io/en/latest/E_H.html>`_
  
  - `Image correlation <https://tridimap.readthedocs.io/en/latest/image_correlation.html>`_

Check the different file format possible to import in the TriDiMap toolbox: `File formats <https://tridimap.readthedocs.io/en/latest/examples.html>`_

.. figure:: ./_pictures/MTS_example1_25x25_H_GUI_00.png
   :scale: 40 %
   :align: center
   
   *Plot of the hardness map after loading of data.*
   
..  warning::
    Only square or rectangular indentation grids can be loaded into the Matlab toolbox.

Links
#######

* `Matlab GUI <http://www.mathworks.com/discovery/matlab-gui.html>`_
* `Other links and references <https://tridimap.readthedocs.io/en/latest/links_ref.html>`_
