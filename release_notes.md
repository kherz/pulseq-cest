# pulseq-cest release notes


DONE
- calc_power equivalent calculation added 
- i found pulse shape parameters that look very smilar to teh siemens standard gaussian pulse
	satPulse = mr.makeGaussPulse(fa_sat, 'Duration', t_p, 'system', lims,'timeBwProduct', 0.2,'apodization', 0.5);

- corrected the RF pulse for phase accumulation as in teh scanner for some files 


TODO
- I added calc_power equivalent calculation, this should be added to teh seq file and the plot I think.
- experimnetal multi spin case must be better understood

- corrected the RF pulse for phase accumulation as in teh scanner for some files , must still be done for all of them!


