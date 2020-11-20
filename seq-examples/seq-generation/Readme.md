# How to write a .seq file for the pulseqSBB

This documentation explains the generation of a suitable .seq file for the pulseqSBB simulation and sequence. It uses the the [MATLAB code](https://github.com/pulseq/pulseq/tree/master/matlab/%2Bmr) from the pulseq project. 

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


### Saturation pulses
The pulseq MATLAB package includes a method to create Gaussian pulses directly. All we need to do is to calculate the flip angle of a saturation pulse. We also need to define the limits of our system, to ensure that the scanner events are compatible with the system.

```Matlab
lims = mr.opts('MaxGrad',40,'GradUnit','mT/m',...
    'MaxSlew',130,'SlewUnit','T/m/s', ...
    'rfRingdownTime', 30e-6, 'rfDeadTime', 100e-6, 'rfRasterTime',1e-6);

sat_b1 = 2.2; % [uT]
t_p = 50e-3; % [s]

fa_sat = sat_b1 * 42.5764 * 2 * pi * t_p;
satPulse      = mr.makeGaussPulse(fa_sat, 'Duration', t_p, 'system', lims);
```

### Spoiler gradients
With the definition of the MR system we can scale the spoiler gradients by the maximum possible amplitude. The simulation treats an event as a spoiler if it detects all gradients at the same time (the transverse components are set to 0).

```Matlab
spoilAmplitude = 0.8 .* lims.maxGrad; % [Hz/m]
spoilDuration = 4500e-6; % [s]
gxSpoil=mr.makeTrapezoid('x','Amplitude',spoilAmplitude,'Duration',spoilDuration,'system',lims);
gySpoil=mr.makeTrapezoid('y','Amplitude',spoilAmplitude,'Duration',spoilDuration,'system',lims);
gzSpoil=mr.makeTrapezoid('z','Amplitude',spoilAmplitude,'Duration',spoilDuration,'system',lims);
```

### ADC
The ADC event is just a pseudo event as it does not get played out at the scanner and is also not simulated. If you want to simulate the readout as well (only  k-space center as no gradients are simulated) you can add the readout events here (without ADC of course). Make sure you run the correct version at the scanner then, with just the pseudo event and no further readout pulses, gradients or delays.

```Matlab
pseudoADC = mr.makeAdc(1,'Duration', 1e-3);
```

## Fill the sequence object
Once all the sequence events are generated, we can loop through the offsets we want to measure and add the events to the pulseq sequence object. Here is an example for a Z-spectrum from -10 to 10 ppm with 40 measurements.

```Matlab
offset_range = 10;    % [ppm]
num_offsets  = 40;    % number of measurements 
offsets_Hz = linspace(-offset_range,offset_range,num_offsets) * 42.5764 * B0; % Z spec offsets [Hz]
```

As a last step we just need to loop through the frequency offsets we want to measure and add an ADC event after each saturation phase.

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
       seq.addBlock(gxSpoil,gySpoil,gzSpoil); 
    end
    seq.addBlock(pseudoADC); % readout trigger event
end
```

pulseq also supports a plot function, here we can see the Gaussian pulses in the saturation phase. This is how the sequence would look like if you plot the time range from 2.4 (after recovery time) to 4.2 seconds (without an M0 scan). The frequency offset can be seen through the change in phase over time during the pulse.

```Matlab
seq.plot('TimeRange', [2.4 4.2])
```

![sequence diagram](./../example-library/seq_plot_example.png)

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

7. Is there an additional normalization scan acquired. e.g. an unsaturated M<sub>0</sub> scan. How long is the relaxation delay before this scan? Is it acquired after a far-offresonant saturation pulse train? If so, what is the offset frequency, and what was the power used?
