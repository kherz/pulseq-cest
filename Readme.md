# pulseq-cest

Welcome to the **pulseq-cest** repository, a project to faciliate reproducibility in CEST MRI research using the open [pulseq](https://pulseq.github.io/) standard. The repository consists of two parts:
1. [pulseq-cest-library](pulseq-cest-library): 
Here, published and approved CEST saturation blocks are made available.
This allows exact comparison of CEST saturation blocks with newly developed or adapted saturation blocks for reproducible CEST research. All .seq files can be loaded in Matlab for plotting and detailed inspection. This library is maintained in a [separate repository](https://github.com/kherz/pulseq-cest-library) and used as a submodule herein.

2. [pulseq-cest-sim](pulseq-cest-sim): In this folder you can find the  Bloch-McConnell simulation that can be used to simulate and compare different .seq-files for different settings.

More information about both parts can be found in the corresponding subfolders. 

## Installation

The library with all published .seq-files is used as a submodule. You need to run the following command to clone all the files:

`git clone -b external-lib --recurse-submodules https://github.com/kherz/pulseq-cest.git`

Afterwards, add the entire repository to your your Matlab path.

## Getting started
To get an overwiew about the project and how the .seq-files and simulations work, got to the folder [seq-examples/example-library](seq-examples/example-library).
There you will find an example .seq-file which you can simulate and plot.
For plotting, simply run the function 
```Matlab
>> plot_seq_file
```
and choose the [example_APTw.seq](seq-examples/example-library/example_APTw.seq) file. You can have a look at the RF amplitude and phase, as well as the gradient events.

If you want to run the Bloch-McConnell simulation for that Z-spectrum experiment with a standard setting for 3 T, just run
```Matlab
>> Simulate_example
```

For more infos check the subfolder readmes.


