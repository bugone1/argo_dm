    %---remove exceeding presure
    if 0
        for i=1:length(files)
            files(i)
            t(i)=read_nc([dire filesep files(i).name]);
            coef(i)=rmsfit(t(i).longitude,t(i).latitude,datestr(t(i).dates,5),t(i).pres(t(i).temp_qc=='1'),t(i).temp(t(i).temp_qc=='1'),t(i).pres(t(i).psal_qc=='1'),t(i).psal(t(i).psal_qc=='1'),t(i).cycle_number);
            deepest(i)=t(i).pres(end)-2000;
            if length(unique(t(i).pres))~=length(t(i).pres)
                warning(['dups in ' files(i).name]);
                pause
            end
        end
        [ncyc,i]=sort(cat(1,t.cycle_number));
        deepest=deepest(i);coef=coef(i);
        [tr,ok1,ok2]=intersect(presscorrect.cyc,ncyc);
        a(1)=plot(tr,presscorrect.pres(ok1),'b.');
        a(2)=plot(tr,deepest(ok2),'or');
        a(3)=plot(tr,coef(ok2),'.g');
        xlabel('Cycle');
        ylabel('Pressure (db)');
        legend(a,'DM Press correct. according to manual','Deepest pres-2000','Press correct. according to PSAL RMS adjustment',4);
        display('OK?');
        print('-dpng',[lo_system_configuration.FLOAT_PLOTS_DIRECTORY '..' filesep '3pres_' floatname '.png']);
        presscorrect.rms=coef;
        presscorrect.deepest=deepest;
        pause
        close
    end
    %------------
