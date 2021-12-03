# How to write a .seq file for the pulseqSBB

This documentation explains the generation of a suitable .seq file for the pulseqcest simulation and MRI sequence. It uses the the [SequenceSBB](SequenceSBB/@SequenceSBB/SequenceSBB.m) class which is derived from the [Pulseq MATLAB code](https://github.com/pulseq/pulseq/tree/master/matlab/%2Bmr). 

It is also possible to use the [python](https://github.com/imr-framework/pypulseq) package.

## Components of the .seq file

The MATLAB script writes a .seq file for an APTw protocol. The parameters are taken from [cest-sources](https://cest-sources.org/doku.php?id=standard_cest_protocols)

* pulse shape = Gaussian
* B1 = 2.22 µT
* n = 20
* t_p = 50 ms
* t_d = 40 ms
* DC = 0.55 and t_sat = n*(t_p+t_d) = 1.8 s
* T_rec = 2.4/12 s (saturated/M0)

## System Limits
As .seq-files can also be measured at the scanner, it is mandatory to specify the system limits, such as e.g. maximum slew rates etc. You can define them by using the Pulseq mr.opts function:

```Matlab
lims = mr.opts('MaxGrad',40,'GradUnit','mT/m',...
    'MaxSlew',130,'SlewUnit','T/m/s', ...
    'rfRingdownTime', 30e-6, 'rfDeadTime', 100e-6, 'rfRasterTime',1e-6);
```
or call a function to generate some low demanding standard system settings:

```Matlab
lims = getScannerLimits();
```

These limits are used to initialize the *SequenceSBB* object, to make sure that no events with too demanding amplitudes etc. can get added.

```Matlab
seq = SequenceSBB(lims);
```

The *SequenceSBB* class contains all the features of the original *mr.Sequence* in *Pulseq* plus some additional functions that are helpful for our specific CEST applications. It can be used like the regular *mr.Sequence* class.

### Saturation pulses
The *Pulseq* MATLAB package includes a method to create Gaussian pulses directly. All we need to do is to calculate the flip angle of a saturation pulse. If the *SequenceSBB* object *seq* was initialized with system limits (as above), we can directly pass them as ```system``` to the function call (with seq.sys), to make sure we do not exceed any limits.

```Matlab
sat_b1 = 2.2; % [uT]
t_p = 50e-3; % [s]

fa_sat = sat_b1 * 42.5764 * 2 * pi * t_p;
satPulse      = mr.makeGaussPulse(fa_sat, 'Duration', t_p, 'system', seq.sys);
```

### Spoiler gradients
The simulation treats an event as a spoiler if it detects all gradients at the same time and sets the transverse components to 0. The *SequenceSBB* class contains a function to add some low demanding standard spoiler gradients. This is used [later](#fill-the-sequence-object). 

```Matlab
seq.addSpoilerGradients();

```

### ADC
The ADC event is just a pseudo event as it does not get played out at the scanner and is also not simulated. If you want to simulate the readout as well (only k-space center as no gradients are simulated) you can add the readout events here (without ADC of course). Make sure you run the correct version at the scanner then, with just the pseudo event and no further readout pulses, gradients or delays. A pseudo ADC event can be added with the internal *SequenceSBB* function.

```Matlab
seq.addPseudoADCBlock();
```

## Fill the sequence object
Once all the sequence events are generated, we can loop through the offsets we want to measure and add the events to the  *SequenceSBB* object. Here is an example for a Z-spectrum from -10 to 10 ppm with 40 measurements.

```Matlab
offset_range = 10;    % [ppm]
num_offsets  = 40;    % number of measurements 
offsets_Hz = linspace(-offset_range,offset_range,num_offsets) * 42.5764 * B0; % Z spec offsets [Hz]
```

Now, we just need to loop through the frequency offsets we want to simulate/measure and add an ADC event after each saturation phase.

```Matlab
% init sequence
seq = mr.Sequence();
for currentOffset = offsets_Hz
    seq.addBlock(mr.makeDelay(t_rec)); % recovery time
    satPulse.freqOffset = currentOffset; % set frequency offset of the pulse
    for np = 1:n_pulses
        seq.addBlock(satPulse) % add sat pulse
        if np < n_pulses % delay between pulses
            seq.addBlock(mr.makeDelay(t_d)); % add delay
        end
    end
    if spoiling % spoiling before readout
       seq.addSpoilerGradients(); 
    end
    seq.addPseudoADCBlock(); % readout trigger event
end
```

Pulseq also supports a plot function, where sequnce objects can be inspected. We include an additional function, that plots only a single saturation phase (the time between the first and second ADC). This is how the saturation phase would look like. The frequency offset can be seen through the change in phase over time during the pulse.

```Matlab
seq.plotSaturationPhase();
```

![sequence diagram](./../examples/APTw_3T_example.png)

Now, we can save the .seq file and simulate it or run it at the scanner.

```Matlab
seq.write(seq_filename);
```

## Sequence definition questions

When writing your own sequence as a .seq-file, please consider the following points:

1. What is the saturation pulse duration t<sub>p</sub>?

2. What is the interpulse delay t<sub>d</sub> and the duty-cycle DC<sub>sat</sub>= t<sub>p</sub>/(t<sub>p</sub>+t<sub>d</sub>)?

3. What is the saturation pulse flip angle? What is the average amplitude of the pulse, the average amplitude of the pulse train (cwae) and the average power (cwpe) of the pulse train?

4. What is the exact pulse shape? Can it be given as a text file with sampling points?

5. What is the phase after the RF pulse? Is it set to zero or is the accumulated phase kept as it is?

6. What is the exact T<sub>rec</sub> used, meaning the time between the last readout pulse and  the next saturation phase?

7. Is there an additional normalization scan acquired. e.g. an unsaturated M<sub>0</sub> scan. How long is the relaxation delay before this scan? Is it acquired after a far off-resonant saturation pulse train? If so, what is the offset frequency, and what was the power used?
