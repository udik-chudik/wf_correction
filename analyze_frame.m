function objects = analyze_frame(frame)
    % first 2 bytes type: 
    objects = [];
    
    if (resolve_type(frame(1:2)) == "COMPOSITE_OBJECT")
        num_of_elements = getShortInt(frame(3:4));
        % got number of elements in composite object
        frame = frame(5:end);
        header = [];
        items_frame = [];
        while (num_of_elements > 0)
            h = struct();
            len = getInt(frame(1:4));
            h.type = resolve_type(frame(5:7));
            h.raw = 0;
            if h.type == "ITEMS"
                h.raw = [items_frame frame(1:len)];
                
                %offset = 1;
                %while offset -  < len
                %    item_len = getInt(frame(8:11));
                %    frame_items = [frame_items frame(8:item_len)];
                %    offset = offset + item_len + 2;
                %end
                
            end
            frame = frame(len + 1:end);
            header = [ header h ];
            %disp(resolve_type(frame(offset+3+1:offset+3+2)));
            %offset = offset + len;
            %[obj, frame] = getObject(frame);
            %disp(obj);
            num_of_elements = num_of_elements - 1;
        end
        % all header elements parsed
        % fill data
        for h=header
            if h.type == "INTEGER"
                h.value = getInt(frame(1:4));
                frame = frame(5:end);
                objects = [objects h];
            elseif h.type == "STRING"
                strlen = getInt(frame(1:4));
                frame = frame(5:end);
                h.value = getString(frame(1:strlen));
                frame = frame(strlen + 1:end);
                if (rem(strlen,2))
                    frame = frame(2:end);
                end
                objects = [objects h];
            elseif h.type == "ITEMS"
                % h.raw = frame with items
                len = getInt(h.raw(1:4));
                offset = 1;
                f = h.raw(5:end);
                
                
                while offset + 6 < len
                    obj = struct();
                    obj.type = "ITEM";
                    item_len = getInt(f(offset+2:offset+2+3));
                    if resolve_type(f(offset+6:offset+7)) == "KEY_VAL"
                        name = resolve_type(f(offset+12:offset+13));
                        if name == "STRING"
                            name_len = getInt(f(offset+14:offset+17));
                            name_len = name_len + rem(name_len,2);
                                
                            name = getString(f(offset+18:offset+18 + name_len - 1));
                            value_type = resolve_type(f(offset+18 + name_len:offset+18 + name_len + 1));
                            kv = struct();
                            kv.value = 0;
                            if value_type == "FLOAT"
                                kv.value = getFloat(f(offset+18 + name_len + 2:offset+18 + name_len + 5));
                            elseif value_type == "SHORT_INT"
                                kv.value = getShortInt(f(offset+18 + name_len + 2:offset+18 + name_len + 3));
                            elseif value_type == "ARRAY"
                                % fuck. this it hard
                                dim_number = getShortInt(f(offset+18 + name_len + 1 + 2 - 1:offset+18 + name_len + 2 + 2 -1));
                                elements_type = resolve_type(f(offset+18 + name_len + 1 + 2 + 2+4 -1:offset+18 + name_len + 2 + 2 + 2+4 -1));
                                arr_len = getInt(f(offset+18 + name_len + 1 + 2 + 2 + 2 + 4 -1:offset+18 + name_len + 2 + 2 + 2 + 2 + 4 + 2 -1));
                                arr_values = [];
                                if dim_number == 1
                                    for i=1:arr_len
                                        if elements_type == "FLOAT"
                                            arr_values = [arr_values getFloat(f(offset+18 + name_len + 2 + 2 + 2 + 2 + 4 + 2 + 1 + (i-1)*4 -1:offset+18 + name_len + 2 + 2 + 2 + 2 + 4 + 2 + 1 + (i-1)*4 + 3 -1))];
                                        end
                                    end                                    
                                elseif dim_number == 2
                                    arr_len_x = arr_len;
                                    arr_len_y = getInt(f(offset+18 + name_len + 1 + 2 + 2 + 2 + 4 -1 + 4:offset+18 + name_len + 2 + 2 + 2 + 2 + 4 + 2 -1 + 4));
                                    arr_values = [arr_len_x arr_len_y];
                                    for x=1:arr_len_x
                                        row = [];
                                        for y=1:arr_len_y
                                            row = [row getFloat(f(offset+18 + name_len + 2 + 2 + 2 + 2 + 4 + 2 + 1 + 4 + (y-1)*4 + (x-1)*4*arr_len_x -1:offset+18 + name_len + 2 + 2 + 2 + 2 + 4 + 2 + 1 + 4 + (y-1)*4 + (x-1)*4*arr_len_x + 3 -1))];
                                        end
                                        if x == 1
                                            arr_values = row;
                                        else
                                            arr_values = [arr_values; row];
                                        end
                                    end
                                    %arr_values = arr_values';
                                end
                                kv.value = arr_values;
                            end
                            kv.name = name;
                            obj.value = kv;
                        end
                        
                    end
                    obj.raw = f(offset+2:offset+item_len);
                    %obj.value = f(offset+2:offset+item_len);
                    offset = offset + item_len + 2;
                    objects = [objects obj];
                end
                
            end
            
        end
    else
        disp("WARNING! Unknown frame object type!");
    end
    
   
end

function type = resolve_type(magic_bytes)
    if (magic_bytes(1) == 1) && (magic_bytes(2) == 8)
        type = "COMPOSITE_OBJECT";
    elseif (magic_bytes(1) == 0) && (magic_bytes(2) == 3)
        type = "INTEGER";
    elseif (magic_bytes(1) == 0) && (magic_bytes(2) == 9)
        type = "STRING";
    elseif (magic_bytes(1) == 2) && (magic_bytes(2) == 64)
        type = "ITEMS";
    elseif (magic_bytes(1) == 3) && (magic_bytes(2) == 64)
        type = "KEY_VAL";
    elseif (magic_bytes(1) == 2) && (magic_bytes(2) == 3)
        type = "FLOAT";
    elseif (magic_bytes(1) == 0) && (magic_bytes(2) == 2)
        type = "SHORT_INT";
    elseif (magic_bytes(1) == 0) && (magic_bytes(2) == 8)
        type = "ARRAY";
    else
        type = "UNKNOWN";
    end
end

function [obj, new_frame] = getObject(frame)
    offset = 1;
    len = getInt(frame(offset:offset + 3));
    offset = offset + 4;
    type = resolve_type(frame(offset:offset+1));
    offset = offset + 2;
    if (type == "INTEGER")
        obj = struct("INTEGER", getInt(offset:offset + 3));
    else
        disp("Error, unknown object type!");
    end
    new_frame = frame(len+1:end);
end

function num = getShortInt(bytes)
    num = typecast(uint8(bytes), 'uint16');
    num = double(num);
end

function str = getString(bytes)
    if bytes(end) == 0
        str = erase(join(string(char(bytes(1:end-1)))), " ");    
    else
        str = erase(join(string(char(bytes(1:end)))), " ");
    end
    
end

function num = getFloat(bytes)
    num = typecast(bytes, 'single');
end

function num = getInt(bytes)
    num = typecast(uint8(bytes), 'uint32');
    num = double(num);
end