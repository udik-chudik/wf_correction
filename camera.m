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

global ERRS;

ERRS = [];

was_stop = 0;

N_ACT = 3;

cx = 1022; % увеличение - влево
cy = 460; % уменьшение - вверх


showInitPattern();






% Add NET assembly if it does not exist
% May need to change specific location of library
asm = System.AppDomain.CurrentDomain.GetAssemblies;
if ~any(arrayfun(@(n) strncmpi(char(asm.Get(n-1).FullName), ...
  'uEyeDotNet', length('uEyeDotNet')), 1:asm.Length))
 NET.addAssembly(...
  'C:\Program Files\IDS\uEye\Develop\DotNet\signed\uEyeDotNet.dll');
end



% Create camera object
cam = uEye.Camera;

% Initialize camera, setting window handle for display
% Change the first argument from 0 to camera ID to initialize a specific
% camera, otherwise first camera found will be initialized
cam.Init(0);

% Ensure Direct3D mode is set
cam.Display.Mode.Set(uEye.Defines.DisplayMode.Direct3D);

% Set to mono
err = cam.PixelFormat.Set(uEye.Defines.ColorMode.Mono8)
% Set exposure
err = cam.Timing.Exposure.Set(1);
% Set AIO
err = cam.Size.AOI.Set(650, 670, 100, 100);
% Set up camera for copying image to Matlab memory for processing
cam.DirectRenderer.SetStealFormat(uEye.Defines.ColorMode.Mono8)
%[err, ID] = cam.Memory.Allocate(true)
[err, ID] = cam.Memory.Allocate(100, 100, 16, true);
[err, Width, Height] = cam.Memory.GetSize(ID)


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

% Start live capture
cam.Acquisition.Capture;
fprintf('Capturing images ...\n');

% Continue until Stop button pressed
T = zeros(10, 1);
tic
%%
%options = optimoptions('simulannealbnd', 'FunctionTolerance', 1e-6);
%x = simulannealbnd(@corrector, zeros(1,N_ACT*N_ACT), ones(1,N_ACT*N_ACT)*-1, ones(1,N_ACT*N_ACT), options);

%%
options = optimoptions('ga', 'FunctionTolerance', 10, 'MaxGenerations', 1000);
x = ga(@corrector, N_ACT*N_ACT, [], [], [],[], ones(1,N_ACT*N_ACT)*-1, ones(1,N_ACT*N_ACT))



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

s = sqrt(length(V));
act = zeros(s, s);
    for i=1:s
        for j=1:s
            act(j,i) = V(s*(i-1)+j);
        end
    end


[X,Y] = ndgrid(1:s,1:s);
F = griddedInterpolant(X,Y,act,'spline');
IMG_SIZE = 500;
[Xq,Yq] = ndgrid(1:s/IMG_SIZE:s,1:s/IMG_SIZE:s);
img = F(Xq,Yq);

% Do correction
apply_correction(img*20);

pause(2*1/60);
% Copy image from graphics card to RAM (wait for completion)
 cam.DirectRenderer.StealNextFrame(uEye.Defines.DeviceParameter.Wait);
 cam.DirectRenderer.StealNextFrame(uEye.Defines.DeviceParameter.Wait);
 
 % Copy image from RAM to Matlab array
 [err, I] = cam.Memory.CopyToArray(ID)
 
  I = reshape(uint8(I), Width, Height).';
    % Plot data
     hImg.CData = I;

     drawnow;
     strehl = 1/double(max(max(I)));

     ERRS = [ERRS strehl];
   
 
 
 
 

 
 
 
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
heds_show_phasevalues(single(phase_data));
end