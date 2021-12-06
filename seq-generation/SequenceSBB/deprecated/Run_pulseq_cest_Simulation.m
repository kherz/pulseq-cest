function M_z = Run_pulseq_cest_Simulation(seq_fn, param_fn)
deprecationWarning(mfilename, 'simulate_pulseqcest');
M_z = simulate_pulseqcest(seq_fn, param_fn);