.. Matlab documentation master file, created by
   sphinx-quickstart on Fri Apr 04 20:28:37 2014.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.
   
.. include:: includes.rst
   
TriDiMap |matlab| toolbox
=======================

.. figure:: ./_pictures/icon_tridimap.png
    :scale: 40 %
    :align: right

The TriDiMap toolbox has been developed to plot, to map and to analyze (nano)indentation
dataset.

With this Matlab toolbox, it is possible:
    * to map (in 2D or 3D), to interpolate and to smooth indentation grid;
    * to plot elastic modulus vs hardness values;
    * to plot and to fit probability density functions;
    * to plot and to fit cumulative density functions;
    * to extract statistical values (mean, min, max with standard deviations) of mechanical properties and fractions for each phase;
    * to correct mechanical map from image correlation with microstructural map.

.. figure:: ./_pictures/download.png
   :scale: 20 %
   :align: left
   :target: https://github.com/DavidMercier/TriDiMap

`Source code is hosted at Github <https://github.com/DavidMercier/TriDiMap>`_.

.. figure:: ./_pictures/normal_folder.png
   :scale: 4 %
   :align: left
   :target: https://github.com/DavidMercier/TriDiMap/archive/tridimap.zip
   
`Download source code as a .zip file <https://github.com/DavidMercier/TriDiMap/archive/master.zip>`_.

.. figure:: ./_pictures/normal_folder.png
   :scale: 4 %
   :align: left
   :target: https://media.readthedocs.org/pdf/tridimap/latest/tridimap.pdf
   
`Download the documentation as a pdf file <https://media.readthedocs.org/pdf/tridimap/latest/tridimap.pdf>`_.
   
.. figure:: ./_pictures/MTS_example1_25x25_H_GUI.gif
   :scale: 80 %
   :align: center
   
   *Screenshot of the TriDiMap toolbox.*

Contents
==========
   
.. toctree::
   :maxdepth: 3
   
   getting_started
   mapping
   pdf_cdf
   E_H
   image_correlation
   examples
   links_ref
   
Contact
=========

:Author: `David Mercier <david9684@gmail.com>`_ [1]

[1] `CRM Group, Avenue du Bois Saint-Jean 21, B27 – Quartier Polytech 4, 4000 Liège, Belgium <http://www.crmgroup.be/>`_

Acknowledgements
==================

The author is grateful to `Dr. Jiri Nemecek <http://ksm.fsv.cvut.cz/~nemecek/?page=resume&lang=en>`_ from (`Czech Technical University <https://www.cvut.cz/en>`_, Czech Republic (Prague))
and to Dr. Nicholas Randall from (`Anton Paar <https://www.anton-paar.com>`_), for discussions and many advices about nanoindentation mapping.

The author is grateful to Debora Rossell (`OCAS <http://www.ocas.be/>`_, Belgium (Zwijnaarde)), for providing example files.

Keywords
==========

|matlab| toolbox ; nanoindentation ; mapping ; grid ; 2D ; 3D ; mechanical properties ;
probability density function ; deconvolution ; multimodal Gaussian fit ; cumulative density function ; image correlation.