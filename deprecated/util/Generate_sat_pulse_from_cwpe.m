function sat_pulse = Generate_sat_pulse_from_cwpe(shape, b1_cwpe, tp,td,lims,gamma_hz)
deprecationWarning(mfilename, 'makeSaturationPulseFromCWPE');
sat_pulse = makeSaturationPulseFromCWPE(shape, b1_cwpe, tp,td,lims);





