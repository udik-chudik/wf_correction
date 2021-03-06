% Import SDK:
add_heds_path;
% Detect SLMs and open a window on the selected SLM:
heds_init_slm;
% Open the SLM preview window (might have an impact on performance):
heds_utils_slm_preview_show;
% Open the SLM preview window (might have an impact on performance):

global cx;          % Center X coordinate on the SLM screen. Horizontal axis, from right to left!
global cy;          % Center Y coordinate on the SLM screen. Vertical axis, from top to bottom!
global gain;        % Correction gain
global phase_data;  % Current SLM phase screen
global frame_count; % Holds current frame number
global errors;      % Array of PV values for every received frame

%phaseModulation = 965*pi;           % Here we setup working tilt to deal with zero-order reflection from SLM
phaseModulation = 957*pi;           % Here we setup working tilt to deal with zero-order reflection from SLM
data_width = heds_slm_width_px;
data_height = heds_slm_height_px;

% Prepare initial phase screen - tilt abberation
phase_data = zeros(data_height,data_width);
for y = 1:data_height
    for x = 1:data_width
        phase_data(y, x) = phaseModulation*x/data_width;
    end
end

cx = 1019; % ���������� - �����
cy = 486; % ���������� - �����
gain = 2*pi/2;

frame_count = 0;
errors = [];

showInitPattern();
wfs_receiver(@process);

%{
%%% Calculate Zernike polynomials Z = Zmn(x,y)
% Lists of angular frequency (m) and radial orders (n)
ZM = [0, -1, 1, -2, 0, 2, -3, -1, 1, 3, -4, -2, 0, 2, 4];
ZN = [0, 1, 1, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4];

% Number of pixilies for X, Y axis for correction
Nx = 443;
Ny = 443;
Z = zeros( Nx, Ny, length(ZM) );
for i = 1:length(ZM)
    Z(:,:,i) = zern(ZM(i), ZN(i), Nx, Ny);
end
%}


    
% This function is called by wfs_receiver when new phase screen has been
% received. wf - new phase screen, PV - calculated Peak to Value
function [] = process(wf, PV)
% Append current PV
global errors;
errors = [errors PV];

% Increase frame count
global frame_count;
frame_count = frame_count + 1;

% Process only every second frame due to distortions caused by applying
% correction on a previous step
if (~(mod(frame_count, 2) == 0))
    return;
end
s = size(wf);

% Get rid of NaN`s in the wf frame
for y = 1:s(1)
    for x = 1:s(2)
    	if isnan(wf(y,x))
        	wf(y,x) = 0;
        end
    end
end

% Crop image - pick out only WF zone from ws frame
% IMPORTANT: zone coordinates depends on HW setup, so current values only
% valid for current setup.
wf = wf(14:33, 8:25);

% Apply necessary transformation
img = imresize(wf, 21.8);

%img = rot90(img);
img = imrotate(img, 90+45+45+45);

% Do correction

if frame_count < 10
    k = 2;
elseif frame_count < 25
    k = 1;
else
    k = 0.25;
end

%k=1;

apply_correction(img, k);
disp(int16(frame_count))
disp(max(max(wf)) - min(min(wf)));

end

% Adds values of array_to_plot to phase_data. cx, cy - center addition
% coordinates
function arr = addArray(phase_data, array_to_plot, cx, cy)
    s = size(array_to_plot);
    sX = cy - round(s(1)/2);
    sY = cx - round(s(2)/2);
    arr = phase_data;
    arr(sX+1:sX+s(1),sY+1:sY+s(2)) = arr(sX+1:sX+s(1),sY+1:sY+s(2)) + array_to_plot;    
end

% Applies correction phase screen to SLM matrix by merging matrices
function [] = apply_correction(corrected, k)
% heds_utils_slm_preview_show;
global cx;
global cy;
global gain;
global phase_data;
phase_data = addArray(phase_data, -corrected*gain*k, cx, cy);

% Show the matrix of phase values on the SLM:
heds_show_phasevalues(single(phase_data));
end

% Display initial pattern - spherical abberation
function [] = showInitPattern()

global phase_data;
global cx;% = 900;   % Center coordinates of the sphere
global cy;% = 440;
siz = 400;  % Size of the pattern in PX on SLM

% Make spherical pattern
sphere = zeros(siz,siz);
for y = 1:siz
    for x = 1:siz
        sphere(y, x) = (((x-siz/2)^2 + (y-siz/2)^2)^(1/2))*pi/(sqrt((siz/2)^2 + (siz/2)^2));
    end
end
phase_data = addArray(phase_data, -sphere*10, cx, cy);
% Show the matrix of phase values on the SLM
heds_show_phasevalues(single(phase_data));
end


