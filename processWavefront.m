function processWavefront(wf)
    
    wf = imresize(wf, 2);
    figure(2);
    imagesc(wf);
end