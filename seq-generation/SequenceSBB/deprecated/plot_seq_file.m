% !! make this files folder your current folder !!
deprecationWarning(mfilename, 'plotSaturationPhase');
if strcmp(mfilename, 'LiveEditorEvaluationHelperESectionEval')
    cd(fileparts(matlab.desktop.editor.getActiveFilename));
else
    cd(fileparts(which(mfilename)));
end
[seqfn, path] = uigetfile({'*.seq','All .seq Files'},'Choose .seq-file to plot'); 
seq = SequenceSBB;
seq.read([path seqfn]);
seq.plotSaturationPhase();
