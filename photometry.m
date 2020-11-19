NET.addAssembly('C:\Program Files\IDS\uEye\Develop\DotNet\signed\uEyeDotNet.dll');


intensity_history = [];

NOISE = 0;

%% Camera routines
cam = uEye.Camera;

cam.Exit();

CAM_ID=1;

exposure_ms=0.5;

cam.Init(CAM_ID);

ColorMode=uEye.Defines.ColorMode.SensorRaw12;

cam.PixelFormat.Set(ColorMode)

cam.AutoFeatures.Sensor.Gain.SetEnable(false);
cam.AutoFeatures.Sensor.Shutter.SetEnable(false);
cam.AutoFeatures.Software.Gain.SetEnable(false);

cam.Trigger.Set(uEye.Defines.TriggerMode.Software);

err = cam.Size.AOI.Set(1100, 800, 300, 300);

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
%axis(hImg.Parent, 'tight');
hx = line(0, 0, 'Color', 'r', 'LineWidth', 2);
hy = line(0, 0, 'Color', 'r', 'LineWidth', 2);

%iText = uilabel(hImg.Parent, 'FontWeight', 'Bold', 'FontSize', 20);
%iText.Text = 'wefwef';

hStp = uicontrol('Style', 'ToggleButton', 'String', 'Stop', ...
    'ForegroundColor', 'r', 'FontWeight', 'Bold', 'FontSize', 20);
hStp.Position(3:4) = [100 50];

% Continue until Stop button pressed
T = zeros(10, 1);
tic
while ~hStp.Value
    
    cam.Acquisition.Freeze(uEye.Defines.DeviceParameter.Wait);
    [tmp, camMemPtr] =  cam.Memory.ToIntPtr;
    
    System.Runtime.InteropServices.Marshal.Copy(camMemPtr, bufArr, 0, imgSize);
    
    img = uint8(bufArr);
    img2 = typecast(img, 'uint16');
    I=reshape(img2, Width, Height)';
    % Plot data
    hImg.CData = I;
    
    NOISE = sum(sum(I(1:100,1:100)));
    INTENSITY = sum(sum(I)) - NOISE*9;
    intensity_history = [intensity_history INTENSITY];
    disp(INTENSITY);
    drawnow;
end

hStp.Value = false;

% Stop capture
cam.Acquisition.Stop;

% Free image memory
cam.Memory.Free(memId);


fprintf('I''ve had enough of that now!!!\n');

% Close camera - ALWAYS make sure the camera is closed before attempting to
% initialize again!!!
cam.Exit;



