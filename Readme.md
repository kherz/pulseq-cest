# pulseq-cest

Welcome to the **pulseq-cest** repository. Here, published and approved CEST saturation blocks are made available in the open pulseq standard (https://pulseq.github.io/).
This allows exact comparison of CEST saturation blocks with newly developed or adapted saturation blocks for reproducible CEST research.
Below you find a list of already defined CEST presaturation schemes as .seq files, together with the corresponding  Matlab generation file.
All .seq files can be loaded in Matlab for plotting and detailed inspection, but also for simulation via the built-in Bloch-McConnell simulation in [pulseq-cest-sim](pulseq-cest-sim).

## Quick start
To view pulseq files in Matlab, download the whole repository, add it to your Matlab path, and run the file **plot_seq_file.m**. You can view either the entire .seq file with all repetitions or have a detailled look at a single saturation phase.
Every .seq file can be simulated by running [pulseq-cest-sim/Run_pulseq_cest_Simulation.m](pulseq-cest-sim/Run_pulseq_cest_Simulation.m). The simulation uses compiled code, which is so available for 64-bit Windows, Linux and Mac OS systems. The source code is included here, if you want to compile the source code for yourself. For more infos about the simulation, have a look at the subfolder [Readme](pulseq-cest-sim/Readme.md).

| SAT identifier with .seq file   and .m file  | scheme  (seq.plot) |  Description  |
|------------------                                                                                             |:-------------------:                                  |-------------:             |
| [APTw_3T_001_2uT_36SincGauss_DC90_2s_braintumor.seq](cest-seq-library/APTw_3T_001_2uT_36SincGauss_DC90_2s_braintumor.seq),<br>[APTw_3T_001_2uT_36SincGauss_DC90_2s_braintumor.m](cest-seq-library/APTw_3T_001_2uT_36SincGauss_DC90_2s_braintumor.m)     | <img src="cest-seq-library/APTw_3T_001_2uT_36SincGauss_DC90_2s_braintumor.png" width="300"/>     | APTw, B1cwpe = 2 µT, Tsat = 1.975 s, DCsat = 90     | 
| [APTw_3T_002_2uT_20SincGauss_DC50_2s_braintumor.seq](cest-seq-library/APTw_3T_002_2uT_20SincGauss_DC50_2s_braintumor.seq),<br>[APTw_3T_002_2uT_20SincGauss_DC50_2s_braintumor.m](cest-seq-library/APTw_3T_002_2uT_20SincGauss_DC50_2s_braintumor.m) | <img src="cest-seq-library/APTw_3T_002_2uT_20SincGauss_DC50_2s_braintumor.png" width="300"/>    | APTw, B1cwpe = 2 µT, Tsat = 1.95 s, DCsat = 50       |  
| [APTw_3T_003_2uT_8block_DC95_834ms_braintumor.seq](cest-seq-library/APTw_3T_003_2uT_8block_DC95_834ms_braintumor.seq),<br>[APTw_3T_003_2uT_8block_DC95_834ms_braintumor.m](cest-seq-library/APTw_3T_003_2uT_8block_DC95_834ms_braintumor.m)                 | <img src="cest-seq-library/APTw_3T_003_2uT_8block_DC95_834ms_braintumor.png" width="300"/>        | APTw, B1cwpe = 2 µT, Tsat = 0.834 s, DCsat = 95   | 


## Sequence definition questions

1. What is the saturation pulse duration t<sub>p</sub>?

2. What is the interpulse delay t<sub>d</sub> and the duty-cycle DC<sub>sat</sub>= t<sub>p</sub>/(t<sub>p</sub>+t<sub>d</sub>)?

3. What is the saturation pulse flip angle? What is the average amplitude of the pulse, the average amplitude of the pulse train (cwae) and the average power (cwpe) of the pulse train?

4. What is the exact pulse shape? Can it be given as a text file with sampling points?

5. What is the phase after the RF pulse? Is it set to zero or is the accumulated phase kept as it is?

6. What is the exact T<sub>rec</sub> used, meaning the time between the last readout pulse and  the next saturation phase?

7. Is there an additional normalization scan acquired. e.g. an unsaturated M<sub>0</sub> scan. How long is the relaxation delay before this scan? Is it acquired after a far-offresonant saturation pulse train? If so, what is the offset frequency, and what was the power used?

