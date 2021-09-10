function M = Sim_pulseqSBB(PMEX, seq_fn)
warning('Sim_pulseqSBB is deprecated, please use pulseqcest instead.');
pulseqcest('init', PMEX, seq_fn);
M = pulseqcest('run');
pulseqcest('close');
