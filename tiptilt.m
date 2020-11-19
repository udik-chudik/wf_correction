NET.addAssembly('C:\Program Files\IDS\uEye\Develop\DotNet\signed\uEyeDotNet.dll');

global mdb;

mdb = modbus('serialrtu','COM5');
write(mdb, 'holdingregs',1,5000);
write(mdb, 'holdingregs',2,5000);
write(mdb, 'holdingregs',3,5000);
%read(m, 'holdingregs',1,1)


global cam;
global hStp;
global bufArr;
global Width;
global Height;
global hImg;
global memId;
global imgSize;
global intensity_history;

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


x = patternsearch(@getIntensity, ones(1,3)*5000, [], [], [],[], ones(1,3)*4000, ones(1,3)*6000);
cleanup();


function I = getIntensity(V)
    
    global hStp;
    global cam;
    global bufArr;
    global imgSize;
    global Width;
    global Height;
    global hImg;
    global intensity_history;
    global mdb;
    
    if (hStp.Value)
        cleanup();
        return;
    end
    
    write(mdb, 'holdingregs',1,round(V(1)));
    write(mdb, 'holdingregs',2,round(V(2)));
    write(mdb, 'holdingregs',3,round(V(3)));
    pause(0.1);
    
    cam.Acquisition.Freeze(uEye.Defines.DeviceParameter.Wait);
    [tmp, camMemPtr] =  cam.Memory.ToIntPtr;
    
    System.Runtime.InteropServices.Marshal.Copy(camMemPtr, bufArr, 0, imgSize);
    
    img = uint8(bufArr);
    img2 = typecast(img, 'uint16');
    I_data=reshape(img2, Width, Height)';
    % Plot data
    hImg.CData = I_data;
    
    NOISE = sum(sum(I_data(1:100,1:100)));
    I = sum(sum(I_data)) - NOISE*9;
    intensity_history = [intensity_history I];
    disp(I);
    drawnow;
end

function cleanup()
global hStp;
global cam;
global memId;
global mdb;
hStp.Value = false;

% Stop capture
cam.Acquisition.Stop;

% Free image memory
cam.Memory.Free(memId);


fprintf('Cleanup complete\n');

% Close camera - ALWAYS make sure the camera is closed before attempting to
% initialize again!!!
cam.Exit;
clear mdb;
end



