# pulseq-cest release notes


DONE
- calc_power equivalent calculation added 
- i found pulse shape parameters that look very smilar to the siemens standard gaussian pulse
	satPulse = mr.makeGaussPulse(fa_sat, 'Duration', t_p, 'system', lims,'timeBwProduct', 0.2,'apodization', 0.5);

- corrected the RF pulse for phase accumulation as in the scanner for all files

- added script for automatic png generation of the seq plot for files in cest-seq-library

- pulse shapes in all sequences is 
mr.makeGaussPulse(fa_sat, 'Duration', t_p, 'system', lims,'timeBwProduct', 0.2,'apodization', 0.5);

TODO (sorted by priority)
- missing for APTw protocols: 
	- proper name
	- exact offset lists
	- the 800ms protocol does not yet have a cwpe adjusted B1 level, due to the funny inter-pulse delays and the DCs the B1 must be a little higher than 2 µT (2µT/DCeff)  but right now 2 µT is used.
  it needs to be tested what the lowest TDs here can be at the scanner.
	- ultimatley, the B1cwpe mus be defined properly ( over pulse train, or over one tp - td element) as one td in the end is missing, small errror, but...

- (add png generation also for simulated Z-spectrum, and add it to website)? 

- make release version

- I added calc_power equivalent calculation, this should be added to the seq file and the plot I think.

- experimental multi spin case must be better understood

- there is too much recurring code between the different script files in the cest-seq-library, this should be cleaned up soon (i started with some generic funtions in the util subfolder)

- for all simulations references must be added where the all quantitative parameters are taken from

