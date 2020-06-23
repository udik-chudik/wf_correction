function [] = wfs_receiver(callBack)
server = tcpip('0.0.0.0', 3015, 'NetworkRole', 'server');
server.InputBufferSize = 65535;

%t.BytesAvailableFcnCount = 4;

set(server, 'BytesAvailableFcnMode', 'byte');
set(server, 'ReadAsyncMode', 'continuous');
set(server, 'BytesAvailableFcn', @onNewData);
set(server, 'BytesAvailableFcnCount', 1);
fopen(server);

function [] = onNewData(t,b)
    %disp("CallBack has been called");
    %uint8(fread(t, t.BytesAvailable));
    %set(t, 'BytesAvailableFcn', @onNewData);
    %return;
    %while 1 > 0
   
    if (t.BytesAvailable >= 4)
       
        frame_length = uint8(fread(t, 4));
        frame_length = double(typecast(frame_length, 'uint32'));
   
        
        while (t.BytesAvailable < frame_length - 4)
        pause(0.001);    
        end
        
            frame = uint8(fread(t, frame_length - 4));
            objects = analyze_frame(frame);
            
            disp("Received command" + objects(1).value);
            
            
            if (objects(1).value == 1)
                % Ignore command == 1
                %return;
            elseif (objects(1).value == 2)
                % should accept connection
                fwrite(t, uint8([28 0 0 0 1 8 2 0 6 0 0 0 0 3 6 0 0 0 0 3 9 0 0 0 2 0 0 0]));
            elseif (objects(1).value == 4)
                % some more magic numbers
                fwrite(t, uint8([0x3a 0x0 0x0 0x0 0x1 0x8 0x3 0x0 0x6 0x0 0x0 0x0 0x0 0x3 0x6 0x0 0x0 0x0 0x0 0x9 0x6 0x0 0x0 0x0 0x0 0x3 0x6 0x0 0x0 0x0 0x13 0x0 0x0 0x0 0x57 0x46 0x53 0x5f 0x57 0x41 0x56 0x45 0x46 0x52 0x4f 0x4e 0x54 0x53 0x45 0x4e 0x53 0x4f 0x52 0x0 0x0 0x0 0x0 0x0]));
            elseif (objects(1).value == 6)
                % new data arrived
                %pause(10);
                x = getField(objects, "Wavefront_Spots_X");
                y = getField(objects, "Wavefront_Spots_Y");
                wf = getField(objects, "Wavefront");
                wf = wf(1:x,1:y);
                %figure(1);
                %imagesc(wf);
                %processWavefront(wf);
                callBack(wf);
            end
    %end
    end
end
    %pause(0.1);
    % wait for the next frame
    %t.BytesAvailableFcnCount = 4;

end