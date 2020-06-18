function arr = getField(objects, field_name)
    for obj=objects
        if obj.type == "ITEM"
            if obj.value.name == field_name
                arr = obj.value.value;
                return
            end
        end
    end
    arr = NaN;
end