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
global MAX_FRAMES_PER_CHANGE;   % Number of frames to acquire to calc mean PV value before change correction coefficients

global t;
global frames;

global Zern_coeff;
MAX_FRAMES_PER_CHANGE = 10;
%%% Calculate Zernike polynomials Z = Zmn(x,y)
% Lists of angular frequency (m) and radial orders (n)
ZM = [0, -1, 1, -2, 0, 2, -3, -1, 1, 3, -4, -2, 0, 2, 4];
ZN = [0, 1, 1, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4];

% Number of pixilies for X, Y axis for correction
Nx = 400;
Ny = Nx;
global Z;
Z = zeros( Nx, Ny, length(ZM) );
for i = 1:length(ZM)
    Z(:,:,i) = zern(ZM(i), ZN(i), Nx, Ny);
end




cx = 1030; % ���������� - �����
cy = 470; % ���������� - �����
gain = 2*pi/20;
scale = 21;
need_connect = 1;



%showShperePattern();
%return;

t = tcpip('0.0.0.0', 3015, 'NetworkRole', 'server');
t.InputBufferSize = 65535;
fopen(t);
frames = 0;

R0 = [0.118    -0.044   -0.028    -0.035   -0.086   -0.008   0.026   0.032    0.022    0.001];

%options = optimoptions('patternsearch', 'MaxFunctionEvaluations', 1000);
%patternsearch(@corrector, R0, [], [], [], [], [], [], [], options)
%fminsearch(@corrector, R0)
%% Start with the default options
options = optimset;
%% Modify options setting
options = optimset(options,'Display', 'off');
options = optimset(options,'TolFun', 0.005);
options = optimset(options,'TolX', 0.000001);
%options = optimset(options,'PlotFcns', { @optimplotfval });
%[x,fval,exitflag,output] = fminsearch(@corrector,R0,options)
gs = GlobalSearch;
opts = optimoptions(@fmincon,'Algorithm','sqp');
problem = createOptimProblem('fmincon', 'x0', R0, 'objective', @corrector,'lb',[-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],'ub',[1,1,1,1,1,1,1,1,1,1],'options',opts);

x = run(gs,problem);
fclose(t);


% Main optimization function
function pv = corrector(R)
    disp("called!")
    % Check coef. bounds
    for i=R
        if abs(i)>1
            pv = 10;
            return;
        end
    end
    global cx;
    global cy;
    global scale;
    global frames;
    global errors;
    global Zern_coeff;
    global MAX_FRAMES_PER_CHANGE;
    global frame_count;
    frames = 0;
    errors = [];
    Zern_coeff = R;
    frame_count = 0;
    showInitPattern();
    wfsr(@process);
    pv = double(mean(errors(1:MAX_FRAMES_PER_CHANGE)));
    disp([pv Zern_coeff]);
end


% This function is called by wfs_receiver when new phase screen has been
% received. wf - new phase screen, PV - calculated Peak to Value
function [] = process(wf, PV)

global scale;
global Z;
global Zern_coeff;
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



sz = size(Z);
sc = size(Zern_coeff);

img = zeros(sz(1),sz(2));
for i=1:sc(2)
    img = img + Z(:,:,i)*Zern_coeff(i);
end
% Do correction
apply_correction(img);

%disp(PV);

%disp(max(max(wf)) - min(min(wf)));

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


%% For looking of img the center
function [] = showShperePattern()

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

% Show the matrix of phase values on the SLM
heds_show_phasevalues(single(addArray(phase_data, -sphere*10, cx, cy)));
end


%% Function called by TCP/IP thread when new data has been arrived from WFS

function [] = wfsr(callBack)
global t;
global frames;
global need_connect;
global MAX_FRAMES_PER_CHANGE;
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
                
                if (frames > MAX_FRAMES_PER_CHANGE)
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
