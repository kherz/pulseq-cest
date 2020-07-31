# pulseq-cest release notes


DONE
- calc_power equivalent calculation added 
- i found pulse shape parameters that look very smilar to the siemens standard gaussian pulse
	satPulse = mr.makeGaussPulse(fa_sat, 'Duration', t_p, 'system', lims,'timeBwProduct', 0.2,'apodization', 0.5);

- corrected the RF pulse for phase accumulation as in the scanner for all files

- added script for automatic png generation of the seq plot for files in cest-seq-library

- pulse shapes in all sequences is 
mr.makeGaussPulse(fa_sat, 'Duration', t_p, 'system', lims,'timeBwProduct', 0.2,'apodization', 0.5);

TODO

- make release version

- I added calc_power equivalent calculation, this should be added to the seq file and the plot I think.

- experimental multi spin case must be better understood

- there is too much recurring code between the different script files in the cest-seq-library, this should be cleaned up soon (i started with some generic funtions in the util subfolder)

- for all simulations references must be added where the all quantitative parameters are taken from

