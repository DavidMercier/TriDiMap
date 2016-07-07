Matlab functions to plot 3D maps
=================================

Matlab version
------------------
Developed with Matlab R2014a.

Author
----------
Written by D. Mercier [1] (david.mercier@crmgroup.be / david9684@gmail.com).

[1] CRM Group, 4000 Liège, Belgium (`www.crmgroup.be <www.crmgroup.be>`_)

Keywords
---------
Matlab script ; 3D mapping ; 2D projection ; elastic modulus ; hardness ; nanoindentation ; grid.

How to use this Matlab toolbox
-------------------------------
1. Update the "demo.m" Matlab file:
	- path of your dataset ;
	- set interpolation and smoothing steps ;
	- number of indents along X and Y axis ;
	- step size along X and Y axis ;
	- options of plots, colorscale...

2. Run into Matlab the script: demo.m.

3. Answer "yes" to the 1st question in the Command Window of Matlab, in order to add the above folder with subfolders to the matlab search path.

4. Finaly, 3D maps of hardness and elastic modulus are plotted into 2 windows.

Contributors
-------------
- Pierre Huyghes (ULB, Bruxelles) contributed Matlab code.

Screenshots
-------------
.. figure:: pictures/multiMaps.png
   :scale: 50 %
   :align: center
   
   *3D mappings of mechanical properties obtained from indentation tests with different views.*
   
.. figure:: pictures/1_hardnessMap_noInterp_noSmooth.png
   :scale: 50 %
   :align: center
   
   *3D raw mapping of mechanical properties without interpolation and smoothing.*
   
.. figure:: pictures/2_hardnessMap_Interp_noSmooth.png
   :scale: 50 %
   :align: center
   
   *3D mapping of mechanical properties with interpolation and no smoothing.*

.. figure:: pictures/3_hardnessMap_Interp_Smooth.png
   :scale: 50 %
   :align: center
   
   *3D mapping of mechanical properties with interpolation and smoothing.*
   
.. figure:: pictures/3_hardnessDiffMap_InterpSmooth.png
   :scale: 25 %
   :align: center
   
   *Difference map of mechanical properties between interpolated and smoothed data.*
   
.. figure:: pictures/4_hardnessMap_Interp_Smooth_Binarized.png
   :scale: 50 %
   :align: center
   
   *3D mapping of mechanical properties with interpolation, smoothing and binarization.*
   
.. figure:: pictures/4_hardnessDiffMap_Interp_Smooth_Binarized.png
   :scale: 25 %
   :align: center
   
   *Difference map of mechanical properties between interpolated and smoothed/binarized data.*
   
.. figure:: pictures/5_hardnessMap_Interp_Smooth_Discretized.png
   :scale: 50 %
   :align: center
   
   *3D mapping of mechanical properties with interpolation, smoothing and with a discretized scale bar.*
   
.. figure:: pictures/5_hardnessDiffMap_Interp_Smooth_Discretized.png
   :scale: 25 %
   :align: center
   
   *Difference map of mechanical properties between interpolated and smoothed, with a discretized scale bar.*
   