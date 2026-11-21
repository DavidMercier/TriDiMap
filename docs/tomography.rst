Nanoindentation tomography
============================

.. include:: includes.rst

3D / 4D map
-------------

The instrumented indentation technique usually provides contact stiffness, indenter displacement, and applied load as functions of position (horizontal and vertical),
within the tested material volume when using dynamic mode (i.e., continuous stiffness measurement or CSM). Such experiments can provide precise and accurate mechanical-property gradients [#Tromas_2012]_ or tomograms [#Coy_2016]_ (i.e., volumetric information). Each indentation depth corresponds to a mechanical-property map (i.e., a slice).

By stacking the maps or slices, it is possible to generate a 3D representation of the indentation experiment. An example of a 3D map is available in the literature [#Wu_2021]_. Such maps are sometimes described as 4D maps [#Coy_2016]_, with the first and second dimensions representing indentation position,
the third dimension representing indentation depth, and the fourth dimension representing the mechanical-property value.

Some options are available for the graphical rendering of the tomographic visualization.
For example, it is possible to modify the "Z axis ratio" value, to increase or decrease the vertical over the horizontal scale ratio.
The higher this ratio, the lower the vertical expansion. Another option is transparency. You can
make the tomogram fully opaque (variable set to 1) or fully transparent (variable set to 0).

The |matlab| function used to generate 3D or 4D maps is: `slice.m <https://fr.mathworks.com/help/matlab/ref/slice.html>`_

..  warning::
    This is not a 3D reconstruction, so the slices do not need to be aligned, rotated, or distorted. Misalignment or local disorientation can occur only if the indentation direction is not perpendicular to the sample surface.

.. only:: html

    .. figure:: ./_pictures/gif_4Dmap/25x25pixels_25slices.gif
        :scale: 60 %
        :align: center
        
        *4D mapping of sample hardness obtained from indentation tests (25x25 pixels x25 slices)*
   
.. only:: latex

    .. figure:: ./_pictures/gif_4Dmap/MTS_example1_25x25.xls_3DSlice.mat_01.png
        :scale: 100 %
        :align: center
        
        *4D mapping of sample hardness obtained from indentation tests (25x25 pixels x25 slices)*

.. note::
    To generate a 4D map, you must load the raw *.xls files the first time. The imported data is saved as a *.mat file in the same folder, so next time you can load only this *.mat file to reduce loading time.

For spreadsheets with sheets named ``Test 001``, ``Test 002``, and so on,
curves are imported in test-number order, matching the results table rather
than the worksheet order. Numbered tests must be consecutive and match the
map's grid dimensions. A test missing the selected end segment keeps its grid
position as a missing value and generates a warning; the subsequent map
cleaning step may fill missing pixels. Re-import the workbook to regenerate
an older cached MAT file if its curves are in worksheet order.

Example of a .mat file: `MTS_example1_25x25.xls_3DSlice.mat <https://github.com/DavidMercier/TriDiMap/blob/master/data_indentation/MTS_example1_25x25.xls_3DSlice.mat>`_

Other 3D view
-------------

Using the TriDiMap toolbox and 'Powerpoint',
the following figure can be obtained by doing a combination of surface and in-depth indentation maps.

    .. figure:: ./_pictures/cs_map.png
        :scale: 100 %
        :align: center
        
        *View of a combination of surface and in-depth indentation maps*
		
References
-------------
.. [#Tromas_2012] `Tromas C. et al., "Hardness and elastic modulus gradients in plasma-nitrided 316L polycrystalline stainless steel investigated by nanoindentation tomography" (2012). <https://doi.org/10.1016/j.actamat.2011.12.012>`_
.. [#Coy_2016] `Coy E. et al., "Topographic reconstruction and mechanical analysis of atomic layer deposited Al2O3/TiO2 nanolaminates by nanoindentation" (2016). <https://doi.org/10.1016/j.matdes.2016.09.030>`_
.. [#Wu_2021] `Wu Y. et al., "Understanding the effect of extractives on the mechanical properties of the waterborne coating on wood surface by nanoindentation 3D mapping" (2021). <https://doi.org/10.1007/s10853-020-05347-2>`_

