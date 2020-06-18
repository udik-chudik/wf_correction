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

cx = 943;
cy = 380;
gain = 10;
siz = 100;

fig = uifigure('Position',[100 100 350 275]);
sldx = uislider(fig,...
    'Position',[100 75 120 3],...
    'ValueChangedFcn',@(sld,event) sliderX(sld,cx));
sldx.Limits = [700 1100];
sldx.Value = cx;

sldy = uislider(fig,...
    'Position',[100 125 120 3],...
    'ValueChangedFcn',@(sld,event) sliderY(sld,cy));
sldy.Limits = [200 600];
sldy.Value = cy;

sldg = uislider(fig,...
    'Position',[100 175 120 3],...
    'ValueChangedFcn',@(sld,event) sliderGain(sld,cy));
sldg.Limits = [-10 10];
sldg.Value = gain;

slds = uislider(fig,...
    'Position',[100 225 120 3],...
    'ValueChangedFcn',@(sld,event) sliderSiz(sld,cy));
slds.Limits = [10 300];
slds.Value = siz;







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

sphere = zeros(100,100);

for y = 1:siz
    for x = 1:siz
        sphere(y, x) = (((x-50)^2 + (y-50)^2)^(1/2))*pi/(sqrt(50^2 + 50^2));
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

