% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  
%  Copyright (C) 2018 HOLOEYE Photonics AG. All rights reserved.
%  Contact: https://holoeye.com/contact/
%  
%  This file is part of HOLOEYE SLM Display SDK.
%  
%  You may use this file under the terms and conditions of the
%  "HOLOEYE SLM Display SDK Standard License v1.0" license agreement.
%  
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
% Calculates an axicon and shows it on the SLM.

% Import SDK:
add_heds_path;

% Detect SLMs and open a window on the selected SLM:
heds_init_slm;

% Open the SLM preview window (might have an impact on performance):
% heds_utils_slm_preview_show;
phaseModulation = 800*pi;
dataWidth = heds_slm_width_px;
dataHeight = heds_slm_height_px;

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

delta = imresize(phase_raw, 30);
delta = imrotate(delta, 60, 'crop');
s = size(delta);

for y = 1:s(1)
    for x = 1:s(2)
        if (isnan(delta(y,x)))
            delta(y,x) = 0;
        end
    end
end

sX = 100;
sY = 1;


phaseData(sY:sY+s(1)-1, sX:sX+s(2)-1) = phaseData(sY:sY+s(1)-1, sX:sX+s(2)-1) - delta*2*pi;

%here we have tilted wave front - separated 0th order from 1 order



% Show the matrix of phase values on the SLM:
heds_show_phasevalues(phaseData);

% Please uncomment to close SDK at the end:
% heds_close_slm