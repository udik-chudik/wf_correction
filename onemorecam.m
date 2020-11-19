NET.addAssembly('C:\Program Files\IDS\uEye\Develop\DotNet\signed\uEyeDotNet.dll');

% Import SDK:
add_heds_path;
% Detect SLMs and open a window on the selected SLM:
heds_init_slm;
% Open the SLM preview window (might have an impact on performance):
heds_utils_slm_preview_show;
% Open the SLM preview window (might have an impact on performance):

global cx;
global cy;

global phase_data;
global was_stop;
global cam;
global ID;
global Width;
global Height;
global hImg;
global bufArr;
global ERRS;
global imgSize;
ERRS = [];

was_stop = 0;

N_ACT = 11;

cx = 1022; % увеличение - влево
cy = 460; % уменьшение - вверх


showInitPattern();

%%
% All about zern
% Lists of angular frequency (m) and radial orders (n)
ZM = [0, -1, 1, -2, 0, 2, -3, -1, 1, 3, -4, -2, 0, 2, 4, -5, -3, -1, 1, 3, 5, -6, -4, -2, 0, 2, 4, 6];
ZN = [0,  1, 1,  2, 2, 2,  3,  3, 3, 3,  4,  4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6];
% Number of pixilies for X, Y axis for correction
Nx = 600;
Ny = Nx;
global Z;
Z = zeros( Nx, Ny, length(ZM) );
for i = 1:length(ZM)
    Z(:,:,i) = zern(ZM(i), ZN(i), Nx, Ny);
end



%% Camera routines
cam = uEye.Camera;

cam.Exit();

CAM_ID=1;

exposure_ms=0.003;

cam.Init(CAM_ID);

ColorMode=uEye.Defines.ColorMode.SensorRaw12;

cam.PixelFormat.Set(ColorMode)

cam.AutoFeatures.Sensor.Gain.SetEnable(false);
cam.AutoFeatures.Sensor.Shutter.SetEnable(false);
cam.AutoFeatures.Software.Gain.SetEnable(false);

cam.Trigger.Set(uEye.Defines.TriggerMode.Software);

err = cam.Size.AOI.Set(1180, 870, 100, 100);

[tmp, memId] = cam.Memory.Allocate(true);

[tmp, Width] = cam.Memory.GetWidth(memId);

[tmp, Height] = cam.Memory.GetHeight(memId);

[tmp, imgBpp] = cam.Memory.GetBitsPerPixel(memId);

imgBpp = 2;

imgSize = Width * Height * imgBpp;

bufArr = NET.createArray('System.Byte', imgSize);


cam.Timing.Exposure.Set(exposure_ms); % msec

% Set up matlab figure for processed image
clf
hImg = imagesc;
axis(hImg.Parent, 'image');
axis(hImg.Parent, 'tight');
hx = line(0, 0, 'Color', 'r', 'LineWidth', 2);
hy = line(0, 0, 'Color', 'r', 'LineWidth', 2);

global hStp;

hStp = uicontrol('Style', 'ToggleButton', 'String', 'Stop', ...
 'ForegroundColor', 'r', 'FontWeight', 'Bold', 'FontSize', 20);
hStp.Position(3:4) = [100 50];




% Continue until Stop button pressed
T = zeros(10, 1);
tic
%%

%options = optimoptions('simulannealbnd', 'FunctionTolerance', 1e-6);
%x = simulannealbnd(@corrector, zeros(1,N_ACT*N_ACT), ones(1,N_ACT*N_ACT)*-0.5, ones(1,N_ACT*N_ACT)*0.5, options);

%%
%options = optimoptions('ga', 'FunctionTolerance', 10, 'MaxGenerations', 1000);
x = ga(@corrector, N_ACT*N_ACT, [], [], [],[], ones(1,N_ACT*N_ACT)*-0.5, ones(1,N_ACT*N_ACT)*0.5)
%x = patternsearch(@corrector, zeros(1,N_ACT*N_ACT), [], [], [],[], ones(1,N_ACT*N_ACT)*-0.5, ones(1,N_ACT*N_ACT)*0.5);
%x = ga(@corrector, 28, [], [], [],[], ones(1,15)*-0.5, ones(1,15)*0.5)

cam.Exit();

%% Main correction procedure
% Takes V - as input vector (matrix of actuator heights) and returns value similar to shrehl ratio
function strehl = corrector(V)

global was_stop;
global hStp;
global cam;
global ID;
global Width;
global Height;
global hImg;
global ERRS;
global bufArr;
global imgSize;
showInitPattern();
if hStp.Value
    hStp.Value = false;

    % Stop capture
    cam.Acquisition.Stop;

    % Free image memory
    cam.Memory.Free(ID);


    fprintf('I''ve had enough of that now!!!\n');

    % Close camera - ALWAYS make sure the camera is closed before attempting to
    % initialize again!!!
    cam.Exit;
    was_stop = 2;
end

if was_stop > 0
    strehl = 0;
    return;
end
% optimum for 3x3 and multiply 20
%V = [-0.6574   -0.5059    0.4030   -0.5884   -0.5655   -0.6318   -0.6593   -0.5040   -0.7555];
%V = [-0.4961   -0.7460    0.0053   -0.4924    0.0948    0.1290    0.6888    0.8530    0.0466   -0.7885    0.6565    0.3722    0.5158    0.3870   -0.9036   -0.1125    0.4175    0.6199    0.1799    0.9822 -0.1911    0.2566   -0.3257    0.8105   -0.4648];
%V = [-0.1956   -0.1997    0.1132    0.1132   -0.1999    0.1053   -0.1053 -0.1056   -0.1813]


s = sqrt(length(V));
act = zeros(s, s);
    for i=1:s
        for j=1:s
            act(j,i) = V(s*(i-1)+j);
        end
    end


[X,Y] = ndgrid(1:s,1:s);
F = griddedInterpolant(X,Y,act,'spline');
IMG_SIZE = 600;
[Xq,Yq] = ndgrid(1:s/IMG_SIZE:s,1:s/IMG_SIZE:s);
img = F(Xq,Yq);



%%
% Zernikie
%{
global Z;
sz = size(Z);
sc = length(V);

img = zeros(sz(1),sz(2));
for i=1:sc
    img = img + Z(:,:,i)*V(i)/i;
end
%}
%%

% Do correction
apply_correction(img*5);

pause(2/60);
% Copy image from graphics card to RAM (wait for completion)
cam.Acquisition.Freeze(uEye.Defines.DeviceParameter.Wait);
%cam.Acquisition.Freeze(uEye.Defines.DeviceParameter.Wait);
%cam.Acquisition.Freeze(uEye.Defines.DeviceParameter.Wait);
[tmp, camMemPtr] =  cam.Memory.ToIntPtr;

System.Runtime.InteropServices.Marshal.Copy(camMemPtr, bufArr, 0, imgSize);

img = uint8(bufArr);
img2 = typecast(img, 'uint16');
I=reshape(img2, Width, Height)';
    % Plot data
     %hImg.CData = I;

     drawnow;
     %strehl = 1/double(max(max(I)));
     strehl = sum(sum(I(30:70,45:85))) - sum(sum(1:30,1:30));
     hImg.CData = I(30:70,45:85);
     %strehl = sum(sum(I(40:60,60:80)));
     %strehl = sum(sum(I));
     ERRS = [ERRS strehl];
     disp(strehl);
   
 
 
 
 

 
 
 
end

%% Adds values of array_to_plot to phase_data. cx, cy - center addition
% coordinates
function arr = addArray(phase_data, array_to_plot, cx, cy)
    s = size(array_to_plot);
    sX = round(cy - s(1)/2);
    sY = round(cx - s(2)/2);
    arr = phase_data;
    arr(sX+1:sX+s(1),sY+1:sY+s(2)) = arr(sX+1:sX+s(1),sY+1:sY+s(2)) + array_to_plot;    
end

%% Applies correction phase screen to SLM matrix by merging matrices
function [] = apply_correction(corrected)
% heds_utils_slm_preview_show;
global cx;
global cy;
global phase_data;


% Show the matrix of phase values on the SLM:
heds_show_phasevalues(single(addArray(phase_data, corrected, cx, cy)));
end
%% Display initial pattern - spherical abberation
function [] = showInitPattern()
phaseModulation = 957*pi;           % Here we setup working tilt to deal with zero-order reflection from SLM
data_width = heds_slm_width_px;
data_height = heds_slm_height_px;
global phase_data;
% Prepare initial phase screen - tilt abberation
phase_data = zeros(data_height,data_width);
for y = 1:data_height
    for x = 1:data_width
        phase_data(y, x) = phaseModulation*x/data_width;
    end
end

% Show the matrix of phase values on the SLM
%heds_show_phasevalues(single(phase_data));
end
