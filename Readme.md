[![MATLAB_CI](https://github.com/kherz/pulseq-cest/actions/workflows/ci.yml/badge.svg)](https://github.com/kherz/pulseq-cest/blob/master/.github/workflows/ci.yml)

# pulseq-cest

Welcome to the **pulseq-cest** repository, a project to faciliate reproducibility in CEST MRI research using the open [*Pulseq*](https://pulseq.github.io/) standard. The repository consists of two parts:
1. [pulseq-cest-library](https://github.com/kherz/pulseq-cest-library): 
Here, published and approved CEST preparation periods are made available.
This allows exact comparison of CEST preparation periods with newly developed or adapted blocks for reproducible CEST research. All .seq-files can be loaded in MATLAB for plotting and detailed inspection. This library is maintained in a [separate repository](https://github.com/kherz/pulseq-cest-library) but is included in the pulseq-cest installation.

2. [pulseq-cest-sim](pulseq-cest-sim): In this folder you can find the  Bloch-McConnell simulation that can be used to simulate and compare different .seq-files for different settings.

More information about both parts can be found in the corresponding repository or subfolder. 

If you prefer **python** over MATLAB, have a look at the python version of the project [here](https://github.com/KerstinHut/pypulseq-cest).

## Installation

There are 3 ways to install pulseq-cest, listed here in the recommended order:

**1. If you have git installed**
* Clone the repository 
* Open MATLAB
* Run [install_pulseqcest.m](install_pulseqcest.m)
* External packages will be cloned 

**2. If you do not have git installed**
* Download pulseq-cest as .zip 
* Unpack it
* Open MATLAB
* Run [install_pulseqcest.m](install_pulseqcest.m)
* External packages will be downloaded as .zip and unpacked

**3. If you want to do everything manually, or 1. and 2. don't work for you**
* Download pulseq-cest as .zip 
* Unpack it
* Download [pulseq-cest-library](https://github.com/kherz/pulseq-cest-library) as .zip 
* Unpack it in the parent directory of pulseq-cest
* Download [yamlmatlab](https://github.com/ewiger/yamlmatlab) as .zip
* Unpack it in [pulseq-cest/pulseq-cest-sim](pulseq-cest-sim)
* Download [Pulseq](https://github.com/pulseq/pulseq/releases/tag/v1.3.1) as .zip
* Unpack it in [pulseq-cest/pulseq-cest-sim](pulseq-cest-sim)
* Add the pulseq-cest folder and the subfolders to your MATLAB search path

## Getting started
To get an overview about the project and how the .seq-files and simulations work, go to the [examples](examples) folder.
There you will find an example .seq-file for which you can display the different sequence events and run the simulation.

For plotting, just run the following code in the console:
```Matlab
>> seq = SequenceSBB;
>> seq.read('examples/APTw_3T_example.seq');
>> seq.plotSaturationPhase();
```
You can have a look at the RF amplitude and phase, as well as the gradient events.

If you want to run the Bloch-McConnell simulation for that Z-spectrum experiment with a standard setting for 3 T, just run:
```Matlab
>> simulateExample();
```

For more infos check the subfolder Readmes.


