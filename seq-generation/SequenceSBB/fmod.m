%% C++ fmod function (same as on VB and VE)
function m = fmod(a, b)
if a == 0
    m = 0;
else
    m = mod(a, b) + (b*(sign(a) - 1)/2);
end