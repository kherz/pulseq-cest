function PMEX = Read_simulation_params(yaml_fn)
deprecationWarning(mfilename, 'readSimulationParameters');
PMEX = readSimulationParameters(yaml_fn);
