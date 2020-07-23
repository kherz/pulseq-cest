# pulseq-cest release notes


DONE
- calc_power equivalent calculation added 

TODO
- I added calc_power equivalent calculation, thsi should be added to teh seq file and the plot I think.
- pulse shape most similar to the vendor serquences should be added. The standard ones are extremely narrow in their bandwidth which elads to short and strong saturation during the pulse.
It can be done with the parameters of the pulse bt must be compared carefully 

satPulse      = mr.makeGaussPulse(fa_sat, 'Duration', t_p, 'system', lims,'timeBwProduct', 2,'apodization', 0.33);



