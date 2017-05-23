function fname=interactive_qc(local_config,files)
%output fname is a filename with a structure "t" containing t&s data with
%flags for all cycles for a given float
%
floatname=files(1).name(2:8);
fname=[local_config.RAWFLAGSPRES_DIR floatname]; %presscorrect file
dire=[local_config.DATA findnameofsubdir(floatname,listdirs(local_config.DATA))];
clean(dire,files);

%Load working file if exists
t=[];
dokeep=[0 0];
if exist([fname '.mat'],'file')
    tem=load(fname);
    if isfield(tem,'t') %presscorrect file
        cyn1=cat(1,tem.t.cycle_number);
        fnames=char(files.name);
        cyn2=int32(str2num(fnames(:,10:12)));
        [a,b]=setdiff(cyn2,cyn1);
        t=tem.t;
        if ~isempty(b)
            t=aggstruct(t,read_all_nc(dire,files(b),[],[0 0]));
        end
        [tr,j]=unique(cat(1,t.cycle_number));
        t=t(j);
    end
    ynn=input('Do you want to reload QC flags from the netCDF files? (y/n)','s');
    dokeep(1)=lower(ynn(1))=='n';
    ynn=input('Do you want to reload temperature and salinity values from the netCDF files(y/n)','s');
    dokeep(2)=lower(ynn(1))=='n';
end

%Read local netCDF files
if any(dokeep==0)
    t=read_all_nc(dire,files,t,dokeep);
end

%Remove redundant cycles
t=remove_redundant_struct(t,'cycle_number'); %this also sorts the structure by cycle number
cyc1=(cat(1,t.cycle_number));
lf=length(t);

%write KML file for Google Earth
writekml([floatname '.kml'],[cat(1,t.longitude) cat(1,t.latitude)],cat(1,t.cycle_number));
%actxserver([floatname '.kml'])
display(['Start Google Earth and load ' floatname '.kml']);

if isfield(t,'qc')
    qc=cyc1(cat(1,t.qc)==1);
    display(['Cycles Available: ' collapse_vec(cyc1)])
    display(['Visual QC Already Done On ' collapse_vec(qc)])
    nottodo=intersect(cyc1,qc);
    todo=cyc1;
    if ~isempty(nottodo)
        yn=input(['Do you want do perform visual QC on ' collapse_vec(nottodo) 'in addition to un-QCed cycles ?(y/n)'],'s');
        if lower(yn)=='n'
            todo=setdiff(cyc1,qc);
        end
    end
else
    todo=cyc1;
end

if ~isempty(todo)
    q=0;
    i=input('start at which profile?');
    if i<min(cyc1)
        i=min(cyc1);
    end
    i=find(i==cyc1);
    if i>1
        i=i-1;
    end
    while i<lf
        if any(cyc1(i)==todo)
            if (q~=8 || i<2) && q~=0
                i=i+1;
            elseif q~=0 %if user hits backspace
                i=i-1;
            end
            und=find(files(i).name=='_');
            display(files(i).name(und+1:end-3)); %display cycle on command window
            t(i).psal_qc=char(t(i).psal_qc);
            t(i).temp_qc=char(t(i).temp_qc);
            t(i).pres_qc=char(t(i).pres_qc);
            tic;
            [temm,q]=visual_qc(t(i),q);
            temm=rmfield(temm,setdiff(fieldnames(temm),fieldnames(t)));
            t(i)=temm;
            dura=toc;
            %if more than 1 second is spent on the screen, flag this profile as having been visually QCed
            if dura>1
                t(i).qc=1;
            end
        else
            i=i+1;
        end
    end
end

i=input('Was salinity unpumped? y/n','s');
if lower(i)=='y'
    for j=1:lf
        ok=find(t(j).pres<=4);
        t(j).psal_qc(ok)='3';
        t(j).temp_qc(ok)='3';
    end
elseif lower(i)~='n'
    error;
end

%Perform range checks; override visual flags
trio={'temp','psal','pres'};
trio2={'TEMP','SAL','PRES'};
for j=1:length(trio)
    lim.(trio{j})=eval(local_config.(['lim' trio2{j}]));
end
for i=1:lf
    for j=1:length(trio)
        flag.(trio{j})=t(i).(trio{j})>lim.(trio{j})(2) | t(i).(trio{j})<lim.(trio{j})(1) | isnan(t(i).(trio{j}));
    end
    tempOrPres=flag.temp | flag.pres & t(i).temp_qc<'3';
    t(i).psal_qc((flag.psal | tempOrPres) & t(i).psal_qc<'3')='3';
    [t(i).temp_qc(tempOrPres),t(i).ptmp_qc(tempOrPres)]=deal('3');
    t(i).pres_qc(flag.pres & t(i).pres_qc<'3')='3';
end
if exist('tem','var') && isfield(tem,'presscorrect')
    presscorrect=tem.presscorrect;
    save(fname,'t','presscorrect');
else
    save(fname,'t');
end