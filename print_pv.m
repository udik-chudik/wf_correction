
wfs_receiver(@res);

function res(wf, pv)
    disp(max(max(wf))-min(min(wf)));
end