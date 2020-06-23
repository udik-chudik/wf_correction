% Import SDK:
add_heds_path;

% Detect SLMs and open a window on the selected SLM:
heds_init_slm;
% Open the SLM preview window (might have an impact on performance):
heds_utils_slm_preview_show;
% Open the SLM preview window (might have an impact on performance):



global cx;
global cy;
global gain;
global siz;

cx = 900;
cy = 430;
gain = 10;
siz = 100;

fig = uifigure('Position',[100 100 600 275]);
sldx = uislider(fig,...
    'Position',[100 75 200 3],...
    'ValueChangedFcn',@(sld,event) sliderX(sld,cx));
sldx.Limits = [700 1100];
sldx.Value = cx;


sldy = uislider(fig,...
    'Position',[100 125 200 3],...
    'ValueChangedFcn',@(sld,event) sliderY(sld,cy));
sldy.Limits = [200 600];
sldy.Value = cy;

sldg = uislider(fig,...
    'Position',[100 175 200 3],...
    'ValueChangedFcn',@(sld,event) sliderGain(sld,cy));
sldg.Limits = [-10 10];
sldg.Value = gain;

slds = uislider(fig,...
    'Position',[100 225 200 3],...
    'ValueChangedFcn',@(sld,event) sliderSiz(sld,cy));
slds.Limits = [10 500];
slds.Value = siz;

global image1;
image1 = uiaxes(fig, 'Position', [400, 0, 200, 200]);
a = zeros([100 100 3]);
%img = image(image1.ImageSource, a);
imagesc(image1, a);
%image1.ImageSource = a;

wfs_receiver_new(@process);

function [] = process(wf, PV)
global image1;
s = size(wf);
disp(max(max(wf)));
%a = zeros([s(1) s(2) 3]);
%a(:,:,1) = wf;
image(image1, wf);
drawnow;
%set(image1, 'ImageSource', a);
end





function arr = plotArray(phase_data, array_to_plot, cx, cy)
    s = size(array_to_plot);
    sX = cx - round(s(1)/2);
    sY = cy - round(s(2)/2);
    arr = phase_data;
    arr(sY:sY+s(1)-1, sX:sX+s(2)-1) = arr(sY:sY+s(1)-1, sX:sX+s(2)-1) + array_to_plot;
end

function [] = assemblyWF()
% heds_utils_slm_preview_show;
global cx;
global cy;
global gain;
global siz;
phaseModulation = 800*pi;
data_width = heds_slm_width_px;
data_height = heds_slm_height_px;

phase_data = zeros(data_height,data_width);
for y = 1:data_height
    for x = 1:data_width
        phase_data(y, x) = phaseModulation*x/data_width;
    end
end

sphere = zeros(siz,siz);

for y = 1:siz
    for x = 1:siz
        sphere(y, x) = (((x-siz/2)^2 + (y-siz/2)^2)^(1/2))*pi/(sqrt((siz/2)^2 + (siz/2)^2));
    end
end

phase_data = plotArray(phase_data, -sphere*gain, cx, cy);

% Show the matrix of phase values on the SLM:
heds_show_phasevalues(phase_data);
end

function sliderX(sld, value)
global cx;
cx = round(sld.Value);
assemblyWF();
end

function sliderY(sld, value)
global cy;
cy = round(sld.Value);
assemblyWF();
end

function sliderGain(sld, value)
global gain;
gain = round(sld.Value);
assemblyWF();
end

function sliderSiz(sld, value)
global siz;
siz = round(sld.Value);
assemblyWF();
end

