function M = Sim_pulseqSBB(PMEX, seq_fn)
deprecationWarning(mfilename, 'pulseqcest');
M = pulseqcest(PMEX,seq_fn);
