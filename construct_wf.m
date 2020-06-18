function phaseData = construct_wf(dataWidth, dataHeight, wf, X_OFFSET, Y_OFFSET, ~)


rA = 89;
FLIP = 0;
RESIZE = 20.5;%19.5;

%X_OFFSET = 948; // Best before quarantine
%Y_OFFSET = 382; // Best before quarantine

phaseModulation = 1000*pi;
dataWidth_2 = dataWidth / 2;
dataHeight_2 = dataHeight / 2;

% Reserve memory for the phase data matrix.
% Use data type single to optimize performance:
phaseData = zeros(dataHeight, dataWidth, 'single');

% Fill the phaseData matrix:
% Warning: "for"-loops are very slow when using Octave, 
% please refer to "axicon_fast.m" for improvements.
for y = 1:dataHeight
    for x = 1:dataWidth
        phaseData(y, x) = 2*pi + phaseModulation*x/dataWidth;
    end
end


    phase_raw = wf;
    delta = imresize(phase_raw, RESIZE);
    %delta = flip(delta,2);
    if FLIP
        delta = flip(delta,2);
    end
    
    delta = imrotate(delta, rA, 'crop');
    s = size(delta);

    for y = 1:s(1)
        for x = 1:s(2)
            if (isnan(delta(y,x)))
                delta(y,x) = 0;
            end
        end
    end
    siz = 10;
    %delta = delta*0;
    %delta(s(1)/2-siz:s(1)/2+siz,s(2)/2-siz:s(2)/2+siz) = -50;
    
    %for y = 1:s(1)
    %    for x = 1:s(2)
    %        if not(delta(y,x) == 0)
    %            if y > s(1)/3 && y < s(1)*2/3 && x > s(2)/3 && x < s(2)*2/3
    %                delta(y,x) = 1;
    %        end
    %    end
    %end
    
    
    sX = X_OFFSET - round(s(1)/2);
    sY = Y_OFFSET - round(s(2)/2);


    phaseData(sY:sY+s(1)-1, sX:sX+s(2)-1) = phaseData(sY:sY+s(1)-1, sX:sX+s(2)-1) - delta*1*2*pi;
end