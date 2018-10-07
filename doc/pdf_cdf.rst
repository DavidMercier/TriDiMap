Statistical analysis
==========================

.. include:: includes.rst
 
Probability density function (PDF)
############################################


[#Nemecek_2009]_
[#Nemecek_2010_1]_
[#Nemecek_2010_2]_
[#Nemecek_2010_3]_
[#Nemecek_2013]_
[#Hausild_2016]_

https://github.com/DavidMercier/TriDiMap/blob/master/matlab_code/util/pdfGaussian.m

.. figure:: ./_pictures/MTS_example1_25x25_H_GUI_13.png
   :scale: 50 %
   :align: center
   
   *Histograms of hardness values*
   
   
.. figure:: ./_pictures/MTS_example1_25x25_H_GUI_14.png
   :scale: 50 %
   :align: center
   
   *Histograms of hardness values with Gaussian PDF after fitting and deconvolution step*
   
   
Effect of the interphase... [#Cech_2017]_
   
Cumulative density function (CDF)
############################################


Weibull [#popin]_

https://github.com/DavidMercier/TriDiMap/blob/master/matlab_code/util/cdfGaussian.m
   
.. figure:: ./_pictures/MTS_example1_25x25_H_GUI_15.png
   :scale: 50 %
   :align: center
   
   *Cumulative distribution of hardness values*
   
   
.. figure:: ./_pictures/MTS_example1_25x25_H_GUI_16.png
   :scale: 50 %
   :align: center
   
   *Cumulative distributions of hardness values with Weibull fit*  
   
References
############################################

.. [#Nemecek_2009] `Němeček J., "Nanoindentation of heterogeneous structural materials", PhD thesis (2009). <http://ksm.fsv.cvut.cz/~nemecek/teaching/dmpo/literatura/habilitation%20thesis_Nemecek_CTU-01-2010.pdf>`_
.. [#Nemecek_2010_1] `Němeček J., "Probability density function 1.0" (2010). <http://ksm.fsv.cvut.cz/~nemecek/links/exp2pdf10/exp2pdf10.htm>`_
.. [#Nemecek_2010_2] `Němeček J., "Probability density function 2.1" (2010). <http://ksm.fsv.cvut.cz/~nemecek/links/exp2pdf21/exp2pdf21.htm>`_
.. [#Nemecek_2010_3] `Němeček J., "Deconvolution algorithm 3.0" (2010). <http://ksm.fsv.cvut.cz/~nemecek/links/decon30/decon.htm>`_
.. [#Nemecek_2013] `Němeček J., "Micromechanical analysis of heterogeneous structural materials" (2013). <https://doi.org/10.1016/j.cemconcomp.2012.06.015>`_
.. [#Hausild_2016] `Haušild P. et al., "Determination of the individual phase properties from the measured grid indentation data" (2016). <https://doi.org/10.1557/jmr.2016.375>`_
.. [#Cech_2017] `Čech J.et al., "Approche statistique pour identifier les propriétés mécaniques des phases individuelles à partir de données d’indentation" (2017). <https://doi.org/10.1051/mattech/2016041>`_
.. [#popin] `Mercier D.et al., "PopIn documentation". <https://popin.readthedocs.io/en/latest/models.html#weibull-type-distribution>`_