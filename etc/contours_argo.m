%Created by Mathieu Ouellet; reuse and recycled code belonging to contour_s, contour_t, contour_o and contour_d
%to create only one function of same length as any of the previous ones
%Nov 2008

clear
fs='fontsize';fsn=10;
parm={'temp','psal','oxy'};
units={'ºC','psu',[char(181) 'M']};
varname={'Temperature | Température','Salinity | Salinité','Oxygen | Oxygène'};
tem=char(parm);svn=tem(:,1)';

configfile='ARGOMETAPROFILEPRESS.CSV';
if ~isempty(dir(configfile))
    float_depth=csvread(configfile);
end

%Set contour levels to be displayed
v.p=31:.5:36.5;
v.t=2:26;
v.o=[50 100 200 300 400 500 600 1000];

%Get date range for float
load('recent_date_info.dat')
float=recent_date_info(:,1);
mdyend.s=recent_date_info(:,8:10);
mdyend.t=recent_date_info(:,11:13);
mdyend.o=recent_date_info(:,14:16);
mdy.start=recent_date_info(:,2:4);
mdy.end=recent_date_info(:,5:7);

%Get profiles numbers where delayed mode data is
dmtick=dlmread('recent_dm_prf.dat',' ');

K=1;
%Initialize error file
fid=fopen(['contour_' svn(K) '.err'],'w');
fprintf(fid,'%8s \n','error   ');
fclose(fid);

for jj=1:length(float)
    ylim=[0 2000]; %Programmed depth
    if exist('float_depth','var')
        ok=intersect(float_depth(:,1),float(jj));
        if ~isempty(ok)
            ylim(2)=float_depth(ok,1);
        end
    end
    f_id=int2str(float(jj));
    filename=strcat(parm{K}, f_id, '.bmp');
    startm=int2str(mdy.start(jj,1));
    startd=int2str(mdy.start(jj,2));
    starty=int2str(mdy.start(jj,3));
    tmdy=mdyend.(svn(K));
    endm=int2str(tmdy(jj,1));
    endd=int2str(tmdy(jj,2));
    endy=int2str(tmdy(jj,3));

    for K=1:length(parm)
        %Get data and plot contour
        fname=strcat(parm{K},'_', f_id, '.DAT');
        if ~isempty(dir(fname))
            sample=load(fname);
            %Settings for each figure created
            jet0=ones(1,3);n=64;jet0(2:n+1,:)=jet(n);
            figure('nextplot','add','units','pixels','position',[0 0 800 771],'units','inches','paperposition',[0.083 1.854 8.3 8],'colormap',jet0)
            ax(1)=axes('units','pixels','ydir','reverse','xaxislocation','bottom');

            %Check whether input file has any data, if not create plot with "No data available on it, otherwise continue on
            if ~isempty(sample)
                X = sample(:,end-2);	%station number
                Y = sample(:,end-1);	%depth
                Z = sample(:,end);	%parm value
                clear sample
                thres=100;
                ux=1:max(X);uy=0:1:max(Y)+1;
                [zz,zc]=deal(nan(ux(end),length(uy))); %initialize matrices
                for i=1:length(ux)
                    okt=find(X==ux(i));y=Y(okt);z=Z(okt);
                    if ~isempty(okt)
                        if length(okt)==1 %only one data point
                            [tr,j]=min(abs(uy-y));
                            [zc(i,j(1)),zz(i,j(1))]=deal(z);
                        else %more than one data points
                            zc(i,:)=interp1(y,z,uy); %matrix for contours
                            ok=find(diff(y)>thres); %make sure that any depths separated by vertical gap higher than threshold are not filled
                            while ~isempty(ok)
                                y(ok(1)+2:end+1)=y(ok(1)+1:end);
                                y(ok(1)+1)=y(ok(1))+thres/2;
                                z(ok(1)+2:end+1)=z(ok(1)+1:end);
                                z(ok(1)+1)=nan;
                                ok=find(diff(y)>thres);
                            end
                            zz(i,:)=interp1(y,z,uy);
                        end
                    end
                end
                zz=zz';
                %Mapping the colours manually in order to represent NaNs as white
                clim=minmax(zz); set(gca,'clim',clim);
                mappedzz=(zz-clim(1))/diff(clim)*(n-1)+2;
                mappedzz(isnan(zz))=1;
                %Using "image" rather than "pcolor" or "surface", as these
                %functions don't show the real matrix but
                image(ux,uy,mappedzz);
                clear mappedzz
                set(gca,'xlim',ux([1 end]),'ylim',ylim,'clim',clim)
                C=contour(ux,uy,zz,v.(svn(K)),'k-');
                clabel(C,v.(svn(K)),fs,fsn+1,'fontweight','bold','color','k');
                if ux(end)<=20;     incr=1;
                else               incr=10;
                end
                xtick = 1:incr:ux(end);
                set(ax(1),'xcolor','k','xlim',[1 ux(end)],'ylim',[0 uy(end)],'xtick',xtick,fs,fsn+3);
                % Set colorbar
                cb=colorbar('vertical','units','pixels',fs,fsn+2);
                set(get(cb,'title'),'string',units{K});
                % Set up second axes
                ax(2)=axes('position',get(ax(1),'position'),'unit','pixels','nextplot','add','xaxislocation','bottom');
                set(ax(2),'xlim',get(ax(1),'xlim'),'ylim',get(ax(1),'ylim'));
                set(ax(2),'ytick',[],'yticklabel',[],'color','none',fs,fsn+3,'xtick',get(ax(1),'xtick'));
                % Set up third axes with tick marks at top to indicate delayed mode data
                ax(3)=axes('position',get(ax(2),'position'),'xaxislocation','top');
                set(ax(3),'color','none','nextplot','add');
                set(ax(3),'yticklabel',[],'ytick',[],'xlim',get(ax(1),'xlim'),'ylim',get(ax(1),'ylim'));
                if dmtick(jj,2)==0
                    dmend=[];
                else
                    a=find(dmtick(jj,:));
                    finish=length(a);
                    dmend=dmtick(jj,2:finish);
                end
                set(ax(3),'xtick',dmend,'xticklabel',[],'tickdir','out');
                set(ax,'units','pixels','position',[75 160 650 560]);
            else
                empty=text(1,1,['No data available / Pas de données disponibles']);
                set(empty,'units','pixels','position',[125 250 0],fs,fsn);
                endm=mdy.end(1);
                endd=mdy.end(2);
                endy=mdy.end(3);
            end
            % Labels
            set(get(ax(1),'xlabel'),'string','Station',fs,fsn+5,'fontweight','bold');
            set(get(ax(1),'ylabel'),'string','Pressure / Pression (dbar)',fs,fsn+5,'fontweight','bold');
            title(varname{K},fs,fsn+7,'fontweight','bold');

            %Float ID and date range of the data used
            fl=text(1,1,['\bfFloat/Profileur dérivant:  \rm' f_id]);
            set(fl,'units','pixels','position',[5 -60 0],fs,fsn+4)
            range=text(1,1,['\bfPeriod/Période:  \rm' startm,...
                '/' startd '/' starty '  to/à  ' endm,...
                '/' endd '/' endy]);
            set(range,'units','pixels','position',[5 -80 0],fs,fsn+4)

            %Delayed mode ticks are at the top
            dm=text(1,1,'Tick marks at top indicate stations with delayed mode data');
            set(dm,'units','pixels','position',[5 -100 0],fs,fsn);

            rt=text(1,1,'Les traits de l''axe supérieur indiquent les données en mode différé');
            set(rt,'units','pixels','position',[5 -120 0],fs,fsn);

            text(1,1,['ISDM | GDSI  ' datestr(now,2)],'units','pixels','position',[380 -140 0],fs,fsn);
            print(gcf,'-dbmp16m',filename)
            %    print(gcf,'-dbmp',['b' filename])
            %    print(gcf,'-dbmp16',['d' filename])
            close(figure(jj));
            clear ax
            clf reset;
        end
    end
end

%Write to file if went through all id's with no problems
fid=fopen('contour_s.err','w');
fprintf(fid,'%8s \n','finished');
fclose(fid);
%exit