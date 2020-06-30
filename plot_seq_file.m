% make this fils folder your current folder
%

addpath(genpath(pwd));

seq = mr.Sequence();

seq.read(uigetfile({'*.seq','All .seq Files'},'mytitle','cest-seq-library'));

seq.plot();
