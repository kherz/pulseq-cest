% helper function to read definitions only
% input: .seq filename
% output: seqience definitions
function def = readSequenceDefinitions(seq_fn)
% init output
def = containers.Map();

fid = fopen(seq_fn);

while true && ~feof(fid)
    line = fgetl(fid);
    if (strcmp(line, '[DEFINITIONS]'))
        line = fgetl(fid);
        while ischar(line) && ~(isempty(line) || line(1) == '#')
            tok = textscan(line, '%s');
            def(tok{1}{1}) = str2double(tok{1}(2:end));
            if ~all(isfinite(def(tok{1}{1})))
                def(tok{1}{1}) = strtrim(line((length(tok{1}{1})+2):end));
            end
            line = fgetl(fid);
        end
        break;
    end
    if (strcmp(line, '[BLOCKS]'))
        warning([seq_fn ' does not contain [DEFINITIONS]!']);
        break;
    end
end
fclose(fid);
end