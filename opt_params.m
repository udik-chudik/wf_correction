% Import SDK:
add_heds_path;
% Detect SLMs and open a window on the selected SLM:
heds_init_slm;
% Open the SLM preview window (might have an impact on performance):
heds_utils_slm_preview_show;
% Open the SLM preview window (might have an impact on performance):

global cx;          % Center X coordinate on the SLM screen. Horizontal axis, from right to left!
global cy;          % Center Y coordinate on the SLM screen. Vertical axis, from top to bottom!
global scale;       % Transform coefficeient

global gain;        % Correction gain
global phase_data;  % Current SLM phase screen
global frame_count;
global errors;      % Array of PV values for every received frame
global need_connect;


global t;
global frames;






cx = 901; % увеличение - влево
cy = 440; % уменьшение - вверх
gain = 2*pi/20;
scale = 21;
need_connect = 1;





t = tcpip('0.0.0.0', 3015, 'NetworkRole', 'server');
t.InputBufferSize = 65535;
fopen(t);
frames = 0;

R0 = [901 440 21];
%options = optimoptions('patternsearch', 'MaxFunctionEvaluations', 1000);
%patternsearch(@corrector, R0, [], [], [], [], [], [], [], options)
%fminsearch(@corrector, R0)
%% Start with the default options
options = optimset;
%% Modify options setting
options = optimset(options,'Display', 'off');
options = optimset(options,'TolFun', 0.01);
options = optimset(options,'TolX', 0.5);
%options = optimset(options,'PlotFcns', { @optimplotfval });
[x,fval,exitflag,output] = fminsearch(@corrector,R0,options)

%c = corrector(901, 440, 21);
%disp(c);

fclose(t);


% Main optimization function
function pv = corrector(R)
    if ((R(1) > 1000) || (R(1) < 700) || (R(2) > 700) || (R(2) < 200) || (R(3) > 30) || (R(1) < 10))
        pv = 10;
        return;
    end
    global cx;
    global cy;
    global scale;
    global frames;
    global errors;
    frames = 0;
    errors = [];
    cx = R(1);
    cy = R(2);
    scale = R(3);
    showInitPattern();
    wfsr(@process);
    pv = mean(errors(300:500));
    disp([pv cx cy scale]);
end


% This function is called by wfs_receiver when new phase screen has been
% received. wf - new phase screen, PV - calculated Peak to Value
function [] = process(wf, PV)

global scale;

s = size(wf);

% Get rid of NaN`s in the wf frame
for y = 1:s(1)
    for x = 1:s(2)
    	if isnan(wf(y,x))
        	wf(y,x) = 0;
        end
    end
end

% Append current PV
global errors;
if (nnz(wf==0) < 20)
    errors = [errors 100];
else
    errors = [errors PV];
end

% Increase frame count
global frame_count;
frame_count = frame_count + 1;

% Process only every second frame due to distortions caused by applying
% correction on a previous step
if (~(mod(frame_count, 2) == 0))
    return;
end


% Crop image - pick out only WF zone from ws frame
% IMPORTANT: zone coordinates depends on HW setup, so current values only
% valid for current setup.
%wf = wf(10:31, 5:26);
wf = wf(11:30, 4:23);

% Apply necessary transformation
img = imresize(wf, scale);
img = rot90(img);

% Do correction
apply_correction(img);

%disp(max(max(wf)) - min(min(wf)));

end

% Adds values of array_to_plot to phase_data. cx, cy - center addition
% coordinates
function arr = addArray(phase_data, array_to_plot, cx, cy)
    s = size(array_to_plot);
    sX = round(cy - s(1)/2);
    sY = round(cx - s(2)/2);
    arr = phase_data;
    arr(sX+1:sX+s(1),sY+1:sY+s(2)) = arr(sX+1:sX+s(1),sY+1:sY+s(2)) + array_to_plot;    
end

% Applies correction phase screen to SLM matrix by merging matrices
function [] = apply_correction(corrected)
% heds_utils_slm_preview_show;
global cx;
global cy;
global gain;
global phase_data;

phase_data = addArray(phase_data, -corrected*gain, cx, cy);

% Show the matrix of phase values on the SLM:
heds_show_phasevalues(single(phase_data));
end


% Display initial pattern - spherical abberation
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

cx = 900;   % Center coordinates of the sphere
cy = 440;
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




function [] = wfsr(callBack)
global t;
global frames;
global need_connect;

% Prevent processing of previous unhandled frames
if ((t.BytesAvailable > 0) && (need_connect < 1))
    fread(t, t.BytesAvailable);
end

need_connect = 0;

while 1 > 0 
    if (t.BytesAvailable >= 4)
        frame_length = uint8(fread(t, 4));
        frame_length = double(typecast(frame_length, 'uint32'));
        
        while (t.BytesAvailable < (frame_length - 4))
        pause(0.01);    
        end
        
            frame = uint8(fread(t, frame_length - 4));
            objects = analyze_frame(frame);
            %disp("Received command" + objects(1).value);
            if (objects(1).value == 1)
                % Ignore command == 1
                continue;
            elseif (objects(1).value == 2)
                % should accept connection
                fwrite(t, uint8([28 0 0 0 1 8 2 0 6 0 0 0 0 3 6 0 0 0 0 3 9 0 0 0 2 0 0 0]));
            elseif (objects(1).value == 4)
                % some more magic numbers
                fwrite(t, uint8([0x3a 0x0 0x0 0x0 0x1 0x8 0x3 0x0 0x6 0x0 0x0 0x0 0x0 0x3 0x6 0x0 0x0 0x0 0x0 0x9 0x6 0x0 0x0 0x0 0x0 0x3 0x6 0x0 0x0 0x0 0x13 0x0 0x0 0x0 0x57 0x46 0x53 0x5f 0x57 0x41 0x56 0x45 0x46 0x52 0x4f 0x4e 0x54 0x53 0x45 0x4e 0x53 0x4f 0x52 0x0 0x0 0x0 0x0 0x0]));
            elseif (objects(1).value == 6)
                % new data arrived
                
                x = getField(objects, "Wavefront_Spots_X");
                y = getField(objects, "Wavefront_Spots_Y");
                wf = getField(objects, "Wavefront");
                wf = wf(1:x,1:y);
                PV = getField(objects, "Wavefront_PV");
                callBack(wf, PV);
                frames = frames + 1;
                if (frames > 500)
                    return;
                end
            elseif (objects(1).value == 3)
                % received disconnect option
                fclose(t);
                return;
            end
    end
end
end
