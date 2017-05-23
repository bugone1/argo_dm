

if 0
    
    
    
    if (size(s.psal) == size(s.temp))
        try
            s.ptmp=gsw_pt_from_CT(gsw_SA_from_SP(s.psal,s.pres,s.longitude,s.latitude),s.temp);
        catch
            warning('GSW toolbox not available, trying SeaWater');
            s.ptmp = sw_ptmp(s.psal,s.temp,s.pres,0);
        end
    else
        s.ptmp=[];
    end
end