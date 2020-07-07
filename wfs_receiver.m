function [] = wfs_receiver(callBack)

t = tcpip('0.0.0.0', 3015, 'NetworkRole', 'server');
t.InputBufferSize = 65535;
fopen(t);

while 1 > 0 
    if (t.BytesAvailable >= 4)
        frame_length = uint8(fread(t, 4));
        frame_length = double(typecast(frame_length, 'uint32'));
        
        while (t.BytesAvailable < frame_length - 4)
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
                %if (PV < 0.04)
                %    fclose(t);
                %    return;
                %end
                callBack(wf, PV);
            elseif (objects(1).value == 3)
                % received disconnect option
                fclose(t);
                return;
            end
    end
end
end
