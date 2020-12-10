# pulseq-cest simulation package

## Introduction
This simulation package runs Bloch-McConnell simulations for CEST experiments on [pulseq](http://pulseq.github.io/) sequence files. The MATLAB code can also be used to create .seq files for the pulseq sequence building block for SIEMENS idea sequences. More info about how to use the simulation can be found in the following documentation.

This open source project is published under the [MIT License](LICENSE.md).
Different license terms may apply for included source code in the [3rdParty folder](src/3rdParty).

## Compile the .mex files (skip, if you want to use the included .mex-files)
This package includes precompiled mex files for 64-bit Windows (compiled with MinGW C++ 5.3.0), Linux (compiled on Linux Mint with g++ 7.3.0) and Mac OS.
[eigen](https://gitlab.com/libeigen/eigen/) is used as an external dependency.
If you want or need to compile a version for yourself, there are two different ways:
### 1. MATLAB (simpler approach)

If you do not have git installed, you need to download the [eigen](https://gitlab.com/libeigen/eigen/) package manually and make sure to put the code here */src/3rdParty/eigen3*


 If you have git installed, eigen is cloned during the compilation and you can just run the [compile_pulseqSBB_Sim.m](compile_pulseqSBB_Sim.m) script in MATLAB and should get a similar output like this depending on your compiler: 

```Matlab
>> compile_pulseqSBB_Sim
eigen not found, trying to clone...
...done!
Checking compilers...
Building with 'Microsoft Visual C++ 2017'.
MEX completed successfully.
```

For more infos, have a look at the MATLAB [documentation](https://mathworks.com/help/matlab/call-mex-files-1.html) for mex files.

### 2. CMake (advanced approach)
A [CMakeLists.txt](src/CMakeLists.txt) file is included in the package (tested with MSVC and GCC on Windows). *eigen* is expected to be in */src/3rdParty/eigen3*, but you can change the path manually by changing *EIGEN_SRC_DIR*. If you choose CMake over the MATLAB function, I assume no further instructions are needed here.

## Run example Z-spectrum simulation
This package includes an example [file](../seq-generation/WriteExamplePulseqSBBZSpectrum.m) to generate .seq-files for a APTw Z-spectrum simulation. You can find that in the subfolder [../seq-generation](../seq-generation). Feel free to play around with various parameters to generate different preparation periods. You can find more info in the subfolder [Readme](../seq-generation/Readme.md).

You can simulate  .seq-files by running [Run_pulseq_cest_Simulation.m](Run_pulseq_cest_Simulation.m). The function takes the pulseq .seq-file and a .yaml parameter file with the simulation setting as an input. The parameters from the .yaml-file are [read](Read_simulation_params.m) and used to generate a struct wich is used as input for the mex-function. All members PMEX (**P**arameters for **MEX** ) struct and shortly described here.

### Water Pool (mandatory) 
Water relaxation rates R1 = 1/T1 and R2 = 1/T2 are set here.

```Matlab
PMEX.WaterPool.R1 = 1/1.3;     % Hz
PMEX.WaterPool.R2 = 1/(75e-3); % Hz
PMEX.WaterPool.f  = 1;         % proton fraction
```

### CEST pool(s) (optional)
An arbitrary number of additional CEST pools can be simulated by just defining a multidimensional CESTPool struct. The number of pools is automatically detected in the mex-function. A CEST pool is defined by its relaxation parameters, fraction, chemical shift from water and exchange rate. Here is example for setting two CEST pools:

```Matlab
% pool 1 -> 50 mmol Amide pool
PMEX.CESTPool(1).R1 = PMEX.WaterPool.R1;
PMEX.CESTPool(1).R2 = PMEX.WaterPool.R2;
PMEX.CESTPool(1).f  = 50e-3/111; % fraction
PMEX.CESTPool(1).dw = 3.5; % chemical shift from water [ppm]
PMEX.CESTPool(1).k  = 40; % exchange rate [Hz]

% pool 2 -> 25 mmol Amine pool
PMEX.CESTPool(2).R1 = PMEX.WaterPool.R1;
PMEX.CESTPool(2).R2 = PMEX.WaterPool.R2;
PMEX.CESTPool(2).f  = 25e-3/111; % fraction
PMEX.CESTPool(2).dw = 2; % chemical shift from water [ppm]
PMEX.CESTPool(2).k  = 1000; % exchange rate [Hz]
```
### MT Pool (optional)

A semi-solid MT pool with either a Lorentzian or a SuperLorentzian lineshape can be set as well. It shares the same properties as a CEST pool plus the additional lineshape. A cubic spline interpolation is included for the the SuperLorentzian lineshape to avoid the pole at the chemical shift frequency of the of ssMT pool.   

```Matlab
PMEX.MTPool.R1        = 1;
PMEX.MTPool.R2        = 1e5;
PMEX.MTPool.k         = 23;
PMEX.MTPool.f         = 0.0500;
PMEX.MTPool.dw        = -2;
PMEX.MTPool.Lineshape = 'Lorentzian';
```
### Magnetization vector (mandatory)

When defining the pools as A (Water pool), B (1st CEST pool), C (ssMT pool), D (2nd CEST pool), E (3rd CEST pool) ..., the initial vector is defined as:

M =  [ MxA, MxB, MxD, ... MxN, MyA, MyB, MyD, ... MyN, MzA, MzB, MzD, ... MzN, MzC ]

Usually, you would need to know your approx. magnetization at the end of your readout sequence and set the magnetization vector accordingly. In the example file, a magnetization of Z<sub>i</sub> =  M<sub>i</sub> / M<sub>0</sub> = 0.5 for e.g. a FLASH sequence was assumed.     

```Matlab
nTotalPools = numel(PMEX.CESTPool)+1; % cest + water
PMEX.M = zeros(nTotalPools*3,1);
PMEX.M(nTotalPools*2+1,1)= PMEX.WaterPool.f;
for ii = 2:nTotalPools
    PMEX.M(nTotalPools*2+ii,1)= PMEX.CESTPool(ii-1).f;
    PMEX.M(nTotalPools*2+1,1) = PMEX.M(nTotalPools*2+1,1) - PMEX.CESTPool(ii-1).f;
end
if isfield(PMEX, 'MTPool') && size(PMEX.M,1) == nTotalPools*3 % add MT pool
    PMEX.M = [PMEX.M; PMEX.MTPool.f];
end
PMEX.M = PMEX.M * 0.5;
```

### Field properties 
* B0 (mandatory): field strength [T]
* Gamma (optional): gyromagnetic ration [rad/µT], if not set, default value for H is used (42.577 * 2 * pi)
* B0Inhomogeneity (optional): B0 field inhomogeneity [ppm], default is a homogeneous field (0.0)
* relB1 (roptional): relative B1 field strength, e.g. 0.8 for 80% of B1, default is perfect B1 (1.0) 

```Matlab
% example for H at 3T
PMEX.Scanner.B0    = 3; 
% optional
PMEX.Scanner.Gamma = 267.5153; 
PMEX.Scanner.B0Inhomogeneity = 0.0; 
PMEX.Scanner.relB1           = 1.0; 
```

### Additional optional parameters
* Verbose: true, you want some output info from the mex-funtion. Default is false.
* ResetInitMag: true if magnetization should be set to PMEX.M after each ADC. This can be set to false if you are simulating the readout as well and are interested in the transient magnetization. If false, the current magnetization after the ADC event is not overwritten by the initial magnetization vector. Default is true.
* MaxPulseSamples: max samples for shaped pulses. The simulation detects the shape of the saturation pulse and chooses the minimum required samples automatically. For instance, a block pulse can be simulated with just a single sample, which saves a lot of time. Shaped pulses with more samples than MaxPulseSamples are resampled to that number. Default is 100.

```Matlab
PMEX.Verbose         = false; 
PMEX.ResetInitMag    = true; 
PMEX.MaxPulseSamples = 100; 
```

### Running the simulation
Once all parameters are set, you can simply run the simulation with 
```Matlab
M_out = Sim_pulseqSBB(PMEX, seq_fn);
```
Where PMEX is the sruct with all parameters and seq_fn is the filename of the pulseq .seq file.
The function will return a NxM Matrix where N is the number of entries of the initial magnetization vector PMEX.M and M is the number of ADC events in the .seq file. The Z-value of the water magnetization is at position ((Number of CEST pools) + 1) * 2 + 1 (see definition of the PMEX.M).
