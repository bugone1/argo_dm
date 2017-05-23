%loads MAT files : C:\z\argo_dm\data\float_source\freeland\*.mat
%                  C:\z\argo_dm\data\float_mapped\freeland\map_*.mat
%                  C:\z\argo_dm\data\float_calib\freeland\cal_*.mat
%                  C:\z\argo_dm\data\constants\coastdat.mat
function plot_diagnostics_mat( pn_float_dir, pn_float_name, po_system_configuration )
close all
display(pn_float_name)
pspntb=[1 1 1];
set(0,'defaultfigurerenderer','painters','defaultfigurenextplot','add','defaultaxesnextplot','add')
%<mo>
cmap(:,1)=[0 .36 .7 .875 1 1 1 1 .9 .9]';
cmap(:,2)=[0 .36 .7 .875 1 1 .875 .7 .36 0]';
cmap(:,3)=[.9 .9  1  1   1 1 .875 .7 .36 0]';
symmetricalCMap=cmap;
clear cmap
% modify pn_float_name for title if the name contains '_' ------------
ii=find(pn_float_name=='_');
if(isempty(ii)==0)
    title_floatname = strcat( pn_float_name(1:ii-1), '\_', pn_float_name(ii+1:length(pn_float_name)));
else
    title_floatname = pn_float_name;
end
% load data from /float_source, /float_mapped, /float_calib, and others --------------
lo_float_source_data = load(strcat(po_system_configuration.FLOAT_SOURCE_DIRECTORY, pn_float_dir, pn_float_name, po_system_configuration.FLOAT_SOURCE_POSTFIX));
PROFILE_NO = double(lo_float_source_data.PROFILE_NO);
ii=find(PROFILE_NO~=0); % do not plot profile number 0
PROFILE_NO=PROFILE_NO(ii);
LAT  = lo_float_source_data.LAT(ii) ;
LONG = lo_float_source_data.LONG(ii);
PRES = lo_float_source_data.PRES(:,ii);
PTMP = lo_float_source_data.PTMP(:,ii);
SAL  = lo_float_source_data.SAL(:,ii) ;
if any(~isnan(PRES(:)))   % if no data exists, terminate here, no plots will be produced
    lo_float_mapped_data = load( strcat( po_system_configuration.FLOAT_MAPPED_DIRECTORY, pn_float_dir, po_system_configuration.FLOAT_MAPPED_PREFIX, pn_float_name, po_system_configuration.FLOAT_MAPPED_POSTFIX ) ) ;
    INTERP_PRES = lo_float_mapped_data.la_INTERP_PRES(:,ii) ;
    INTERP_SAL  = lo_float_mapped_data.la_INTERP_SAL(:,ii)  ;
    mapped_sal  = lo_float_mapped_data.la_mapped_sal(:,ii)  ;
    mapsalerrors= lo_float_mapped_data.la_mapsalerrors(:,ii);
    selected_hist=lo_float_mapped_data.selected_hist;
    if any(~isnan(INTERP_PRES(:))) % if no data exists, terminate here, no plots will be produced
        lo_float_calib_data = load(strcat(po_system_configuration.FLOAT_CALIB_DIRECTORY, pn_float_dir, po_system_configuration.FLOAT_CALIB_PREFIX, pn_float_name, po_system_configuration.FLOAT_CALIB_POSTFIX)) ;
        cal_SAL = lo_float_calib_data.cal_SAL(:,ii) ;
        cal_SAL_err = lo_float_calib_data.cal_SAL_err(:,ii) ;
        condslope = lo_float_calib_data.condslope(ii) ;
        condslope_err = lo_float_calib_data.condslope_err(ii) ;
        if any(~isnan(cal_SAL(:))) % if no data exists, terminate here, no plots will be produced
            [m,n] = size(mapped_sal) ;
            number_of_levels = str2double(po_system_configuration.NO_USED_STANDARD_LEVELS) ;
            ptlevels = lo_float_mapped_data.la_standard_levels(1:number_of_levels) ;
            % plot the float locations (figure 1) -----------------------
            load( strcat( po_system_configuration.CONFIG_DIRECTORY, po_system_configuration.CONFIG_COASTLINES ), 'coastdata_x', 'coastdata_y' ) ;
            figure
            colormap(jet(n));
            c=colormap;
            plot(coastdata_x-all(LONG<0)*360,coastdata_y,'k-');
            if ~isempty(selected_hist)
                plot(selected_hist(:,1)-all(LONG<0)*360,selected_hist(:,2),'b.')
                legend('float','historical points','location','best')
            end
            ll=find(LONG>300,1); % make continuous around 0-360 mark
            if ~isempty(ll)
                kk=LONG>0&LONG<50;
                LONG(kk)=360+LONG(kk);
            end
            for i=1:n
                h=plot(LONG(i),LAT(i),'+','color',c(i,:));
                j=text(LONG(i),LAT(i),int2str(PROFILE_NO(i)),'color',c(i,:),'fontsize',12,'hor','cen');
            end
            plot(LONG,LAT,'r-');
            axis([min(LONG) max(LONG) min(LAT) max(LAT)]+[-10 10 -10 10]);set(gca,'FontSize',12);xlabel('Longitude');ylabel('Latitude');
            title( strcat(title_floatname, ' profile locations with historical data' ) );
            drawnow
            set(gcf,'papertype','usletter','paperunits','inches','paperorientation','landscape','paperposition',[.75,.75,9.5,7]);
            if pspntb(1) print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_1.ps'));
            end
            if pspntb(2) print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_1.png'));
            end
            if pspntb(3)
                set(gcf,'paperposition',get(gcf,'paperposition')/3);
                child=get(gcf,'children');
                for c=1:length(child)
                    try
                    set(child(c),'fontsize',6);
                    set(get(child(c),'title'),'fontsize',6);
                    set(get(child(c),'ylabel'),'fontsize',6);
                    set(get(child(c),'xlabel'),'fontsize',6);
                    catch
                    end
                end
                set(gcf,'position',get(gcf,'position')/3);
                print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, 'tb_1.png'));
            end
            close
            % plot the uncalibrated theta-S curves from the float (figure 2) --------
            figure;
            colormap(jet( length([1:ceil(n/24):n]) )); % the legend can only fit 30 profiles. Make that 24 %ron - many replacements below
            c=colormap;
            qq=plot(PTMP(:,1:ceil(n/24):n),SAL(:,1:ceil(n/24):n)); %ron
            for i=1:length([1:ceil(n/24):n]); %ron
                set(qq(i),'color',c(i,:)) ;
            end
            legend(int2str([PROFILE_NO(1:ceil(n/24):n)]'),-1)
            q=errorbar(ptlevels*ones(1,length( [1:ceil(n/24):n] )),mapped_sal(:,1:ceil(n/24):n),mapsalerrors(:,1:ceil(n/24):n),'o');
            for i=1:length([1:ceil(n/24):n])
                set(q(i),'color',c(i,:));
%                set(q(i+length([1:ceil(n/24):n])),'color',c(i,:));
            end
            view([90 -90]);
            set(gca,'FontSize',12)
            ylabel('Salinity (PSS-78)');
            xlabel('\theta ^{\circ} C');

            max_s=max([max(SAL),max(mapped_sal)])+.1;
            min_s=min([min(SAL),min(mapped_sal)])-.1;
            max_t=max(max(PTMP))+1;
            min_t=min(min(PTMP))-1;
            axis([min_t,max_t,min_s,max_s]);

            drawnow
            title( strcat( title_floatname, ' uncalibrated float data (-) and mapped salinity (o) with objective errors' ) );
            set(gcf,'papertype','usletter','paperunits','inches','paperorientation','portrait','paperposition',[.25,.75,8,9.5]);
            if pspntb(1)
                print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_2.ps'));
            end
            if pspntb(2)
                print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_2.png'));
            end
            close

            % plot theta-S curves with errorbars for first and last profiles that have data (figure 3) --------

            good=[];

            for i=1:n
                span=find(isnan(PTMP(:,i))==0);
                if(length(span)>5)good=[good;i];end % if the profile has more than 5 data points
            end
            first=min(good);
            last=max(good);

            max_s=max([max(SAL(:,1)),max(SAL(:,n)),max(mapped_sal(:,1)),max(mapped_sal(:,n))]);
            min_s=min([min(SAL(:,1)),min(SAL(:,n)),min(mapped_sal(:,1)),min(mapped_sal(:,n))]);
            max_t=max([max(PTMP(:,1)),max(PTMP(:,n))]);
            min_t=min([min(PTMP(:,1)),min(PTMP(:,n))]);
            figure;
            if(isempty(good)==0)
               subplot(2,1,1)
                plot(PTMP(:,first),SAL(:,first),'b-');
                plot(ptlevels,mapped_sal(:,first),'ro-');
                ii=find(isfinite(PTMP(:,first))==1);
                plot(PTMP(ii,first),cal_SAL(ii,first),'g-');
                legend('uncal float','mapped sal','cal float w/err.','location','best')
                h=fill([PTMP(ii,first);flipud(PTMP(ii,first))],[cal_SAL(ii,first)-cal_SAL_err(ii,first);flipud(cal_SAL(ii,first)+cal_SAL_err(ii,first))],'g');
                set(h,'EdgeColor','g');
                errorbar(ptlevels,mapped_sal(:,first),mapsalerrors(:,first),'ro');
                plot(PTMP(:,first),SAL(:,first),'b-');
                plot(ptlevels,INTERP_SAL(:,first),'bo');
                set(gca,'FontSize',12)
                xlabel('\theta ^{\circ} C')
                ylabel('Salinity (PSS-78)')
                view([90 -90]);
                title( strcat(title_floatname, ' \theta-S curve for profile #', int2str(PROFILE_NO(first)) ) );
                axis([min_t-1,max_t+1,min_s-.1,max_s+.1]);

                subplot(2,1,2)
                plot(PTMP(:,last),SAL(:,last),'b-');
                plot(ptlevels,mapped_sal(:,last),'ro-');
                ii=find(isfinite(PTMP(:,last))==1);
                plot(PTMP(ii,last),cal_SAL(ii,last),'g-');
                pause(0.5)
                legend('uncal float','mapped sal','cal float w/err.','location','best');
                h=fill([PTMP(ii,last);flipud(PTMP(ii,last))],[cal_SAL(ii,last)-cal_SAL_err(ii,last);flipud(cal_SAL(ii,last)+cal_SAL_err(ii,last))],'g');
                set(h,'EdgeColor','g');
                errorbar(ptlevels,mapped_sal(:,last),mapsalerrors(:,last),'ro');
                plot(PTMP(:,last),SAL(:,last),'b-');
                plot(ptlevels,INTERP_SAL(:,last),'bo');
                set(gca,'FontSize',12)
                xlabel('\theta ^{\circ} C')
                ylabel('Salinity (PSS-78)')
                view([90 -90]);
                title( strcat(title_floatname, ' \theta-S curve for profile #', int2str(PROFILE_NO(last)) ) );
                axis([min_t-1,max_t+1,min_s-.1,max_s+.1]);

            end
            drawnow
            set(gcf,'papertype','usletter','paperunits','inches','paperorientation','portrait','paperposition',[.25,.75,8,9.5]);
            if pspntb(1)
                print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_3.ps'));
            end
            if pspntb(2)
                print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_3.png'));
            end
            close

            % time-varying series (figure 4) --------------------------

            Soffset=cal_SAL-SAL;
            avg_Soffset=NaN.*ones(1,n);
            avg_Soffset_err=NaN.*ones(1,n);

            for i=1:n
                ii=[];
                ii=find(isnan(Soffset(:,i))==0);
                if ~isempty(ii)
                    avg_Soffset(i)=mean(Soffset(ii,i));
                    avg_Soffset_err(i)=mean(cal_SAL_err(ii,i));
                end
            end

            figure
            subplot(2,1,1)
            errorbar(PROFILE_NO(1:n),condslope,condslope_err,'g*-')
            axis([ 0, max(PROFILE_NO)+1, min(condslope)-.0002, max(condslope)+.0002 ])
            plot( [0, max(PROFILE_NO)+1], [1,1], 'k-')
            set(gca,'FontSize',12)
            xlabel('float profile number');
            ylabel('mmho/cm')
            title( strcat(title_floatname, ' potential conductivity multiplicative correction with errors') );

            subplot(2,1,2)
            errorbar(PROFILE_NO(1:n), avg_Soffset, avg_Soffset_err,'go-')
            axis([ 0, max(PROFILE_NO)+1, min(avg_Soffset)-.01, max(avg_Soffset)+.01 ])
            plot( [0, max(PROFILE_NO)+1], [0,0], 'k-')
            set(gca,'FontSize',12)
            xlabel('float profile number');
            ylabel('PSS-78')
            title( strcat(title_floatname, ' equivalent salinity additive correction with errors') );

            drawnow
            set(gcf,'papertype','usletter','paperunits','inches','paperorientation','portrait','paperposition',[.25,.75,8,9.5]);
            if pspntb(1)
                print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_4.ps'));
            end
            if pspntb(2)
                print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_4.png'));
            end
            if pspntb(3)
                set(gcf,'paperposition',get(gcf,'paperposition')/3);
                set(gcf,'position',get(gcf,'position')/3);
                child=get(gcf,'children');
                for c=1:length(child)
                    try
                    set(child(c),'fontsize',6);
                    set(get(child(c),'title'),'fontsize',6);
                    set(get(child(c),'ylabel'),'fontsize',6);
                    set(get(child(c),'xlabel'),'fontsize',6);
                    catch
                    end
                end
                print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, 'tb_4.png'));
            end
            close
            % plot the calibrated theta-S curves from the float (figure 5) --------------------------

            figure;
            colormap(jet( length([1:ceil(n/24):n]))); % the legend can only fit 24 profiles
            c=colormap;

            qq=plot( PTMP(:, 1:ceil(n/24):n), cal_SAL(:, 1:ceil(n/24):n) );
            for i=1:length([1:ceil(n/24):n])
                set(qq(i),'color',c(i,:)) ;
            end
            legend(int2str([PROFILE_NO(1:ceil(n/24):n)]'),-1)
            q=errorbar(ptlevels*ones(1,length( [1:ceil(n/24):n] ) ),mapped_sal(:,1:ceil(n/24):n), mapsalerrors(:,1:ceil(n/24):n),'o');
            for i=1: length([1:ceil(n/24):n])
                set(q(i),'color',c(i,:));
%                set(q(i+length([1:ceil(n/24):n])),'color',c(i,:));
            end
            view([90 -90]);
            set(gca,'FontSize',12)
            xlabel('\theta ^{\circ} C')
            ylabel('Salinity (PSS-78)')

            max_s=max([max(max(cal_SAL)),max(max(mapped_sal))])+.1;
            min_s=min([min(min(cal_SAL)),min(min(mapped_sal))])-.1;
            max_t=max(max(PTMP))+1;
            min_t=min(min(PTMP))-1;
            if(isnan(min_s)==0)
                axis([min_t,max_t,min_s,max_s]);
            end

            drawnow
            title( strcat(title_floatname, ' calibrated float data (-) and mapped salinity (o) with objective errors' ) );
            set(gcf,'papertype','usletter','paperunits','inches','paperorientation','portrait','paperposition',[.25,.75,8,9.5]);
            if pspntb(1)
                print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_5.ps'));
            end
            if pspntb(2)
                print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_5.png'));
            end
            close
            % plot salinity anomaly time series on theta levels (figure 6) ------
            Smedian=NaN.*ones( length(ptlevels), 1);
            for j=1:length(ptlevels)
                jj = find( isnan( INTERP_SAL(j,:) )==0 );
                if(isempty(jj)==0)
                    Smedian(j)= median( INTERP_SAL(j,jj) );
                end
            end

            Sanomaly = INTERP_SAL-Smedian*ones(1,n);
            a=max(max(Sanomaly));
            b=min(min(Sanomaly));
            top=max(max(PTMP));
            bottom=min(min(PTMP));
            if(top>20) %ron
                cut=8;
            elseif(top>10)
                cut=5;
            else
                cut=round((top+3*bottom)/4); %ron
            end

            figure
            if(length(PROFILE_NO)>1)
                subplot('position',[.13 .72 .78 .2])
                colormap(symmetricalCMap) %mathieu
                set(gca,'FontSize',12)
                [c,h]=contourf(PROFILE_NO, ptlevels, Sanomaly, 50); %ron from 25 to 50
                caxis([-1 1]) %ron
                %if(a>b)caxis([b a]);end %ron
                axis([0 max(PROFILE_NO)+1 cut top]);
                set(gca,'XTick',[]);
                set(gca,'XTickLabel',[]);
                title('Float salinity anomaly on potential temperature levels')

                subplot('position',[.13 .11 .78 .61])
                colormap(symmetricalCMap) %mathieu
                set(gca,'FontSize',12)
                if(bottom<cut)
                    [c,h]=contourf(PROFILE_NO, ptlevels, Sanomaly, 50); %ron
                    axis([0 max(PROFILE_NO)+1 bottom cut]);
                end
                caxis([-.1 .1])
                %if(a>b)caxis([b a]);end %ron
                xlabel('float profile number')
                ylabel('\theta ^{\circ} C')
                h2=colorbar('horiz');
                set(h2,'FontSize',12)
            end
            drawnow
            set(gcf,'papertype','usletter','paperunits','inches','paperorientation','portrait','paperposition',[.25,.75,8,9.5]);
            if pspntb(1)
                print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_6.ps'));
            end
            if pspntb(2)
                print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_6.png'));
            end
            if pspntb(3)
                set(gcf,'paperposition',get(gcf,'paperposition')/3);
                child=get(gcf,'children');
                for c=1:length(child)
                    try
                    set(child(c),'fontsize',6);
                    set(get(child(c),'title'),'fontsize',6);
                    set(get(child(c),'ylabel'),'fontsize',6);
                    set(get(child(c),'xlabel'),'fontsize',6);
                    catch
                    end
                end
                print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, 'tb_6.png'));
            end
            close

            % plot salinity time series on level with the smallest mean mapping error (figure 7) ------------
            ICOND=sw_c3515*sw_cndr(INTERP_SAL,ptlevels*ones(1,n),0);
            cal_ICOND=(ones(m,1)*condslope).*ICOND;
            cal_ICOND1=ICOND.*(ones(m,1)*(condslope-condslope_err));
            cal_INTERP_SAL=sw_salt(cal_ICOND/sw_c3515,ptlevels*ones(1,n),0);
            cal_INTERP_SAL_err=abs(cal_INTERP_SAL-sw_salt(cal_ICOND1/sw_c3515,ptlevels*ones(1,n),0));

            merr=NaN*ones(m,1);
            majority=[];
%           majority=find(sum(~isnan(mapsalerrors),1)>n*.7);
            for i=1:m
                jj=find(~isnan(mapsalerrors(i,:)));
                if ~isempty(jj) merr(i)=mean(mapsalerrors(i,jj));end
                if(length(jj)>.7*n) majority=[majority,i];end %these are the levels with at least 70% data
            end
            kk=find(~isnan(merr));
            if ~isempty(kk)
                if ~isempty(majority)
                    ii=find(merr==min(merr(majority)));
                else
                    ii=find(merr==min(merr(kk)));
                end
            else
                ii=[];
            end
            figure
            if ~isempty(ii)
                plot(PROFILE_NO(1:n),INTERP_SAL(ii,:),'b*-');
                plot(PROFILE_NO(1:n),mapped_sal(ii,:),'r');
                plot(PROFILE_NO(1:n),cal_INTERP_SAL(ii,:),'g');
                legend('uncal float','mapped salinity','cal float w/err.','location','best');
                mm=find(isfinite(cal_INTERP_SAL(ii,:))==1); ll=PROFILE_NO(1:n); ll=ll(mm); kk=cal_INTERP_SAL(ii,mm); nn=cal_INTERP_SAL_err(ii,mm);
                h=fill([ll,fliplr(ll)],[kk+nn,fliplr([kk-nn])],'g');
                set(h,'EdgeColor','g');
                errorbar(PROFILE_NO(1:n),mapped_sal(ii,:),mapsalerrors(ii,:),'r-')
                plot(PROFILE_NO(1:n),INTERP_SAL(ii,:),'b*-');
                axis([0, max(PROFILE_NO)+1, min([INTERP_SAL(ii,:),cal_INTERP_SAL(ii,:),mapped_sal(ii,:)])-.05, max([INTERP_SAL(ii,:),cal_INTERP_SAL(ii,:),mapped_sal(ii,:)])+.05 ])
                set(gca,'FontSize',12)
                xlabel('float profile number');
                ylabel('salinity (PSS-78)')
                title( strcat(title_floatname, ' salinities with error on \theta = ', num2str(ptlevels(ii)), ' ^{\circ} C' ) );
            end

            drawnow
            set(gcf,'papertype','usletter','paperunits','inches','paperorientation','portrait','paperposition',[.25,.75,8,9.5]);
            if pspntb(1)
                print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_7.ps'));
            end
            if pspntb(2)
                print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_7.png'));
            end
            if pspntb(3)
                set(gcf,'paperposition',get(gcf,'paperposition')/3);
                child=get(gcf,'children');
                for c=1:length(child)
                    if isfield(child(c),'title')
                        set(child(c),'fontsize',6);
                        set(get(child(c),'title'),'fontsize',6);
                        set(get(child(c),'ylabel'),'fontsize',6);
                        set(get(child(c),'xlabel'),'fontsize',6);
                    end
                end
                print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, 'tb_7.png'));
            end

            close

            figure %ron: plot the salinity anomalies on the deepest 5 levels to look for bad profiles.
            jj=0;
            for i=1:number_of_levels %ron
                ii=[]; %ron
                ii=find(isnan(INTERP_SAL(i,:))==0); %ron
                if(isempty(ii)==0);jj=jj+1;anom_S(jj,:)=INTERP_SAL(i,:)-mean(INTERP_SAL(i,ii))+(jj-1)*.02;used_levels(jj)=ptlevels(i);end; %ron. Offset the anomalies by .02 for each level
            end %ron
            jj_strt=max(1,jj-5);
            plot(PROFILE_NO(1:n),anom_S(jj_strt:jj,1:n),'-o'); %ron
            legend(num2str(used_levels(jj_strt:jj)','%3.1f'),2); %ron
            drawnow %ron
            set(gcf,'papertype','usletter','paperunits','inches','paperorientation','portrait','paperposition',[.25,.75,8,9.5]); %ron
            title( strcat(title_floatname, ' salinity anomalies, offset by .02 on theta = ', ' ^{\circ} C' ) ); %ron
            if pspntb(1)
                print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_8.ps')); %ron
            end
            if pspntb(2)
                print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_8.png')); %ron
            end
            close

            % plot salinity time series on less sampled level with the smallest error (figure 9) ------------
            majority=[];
            merr=NaN*ones(m,1);
            for i=1:m
                jj=find( isnan(mapsalerrors(i,:))==0 );
                if(isempty(jj)==0)merr(i)=mean(mapsalerrors(i,jj));end
                if(length(jj)>.15*n & length(jj)<.7*n)majority=[majority,i];end %these are the levels with at least 20% data to account for the variable profiling depth
            end
            kk=find( isnan(merr)==0 );
            if(isempty(kk)==0)
                if(isempty(majority)==0)
                    ii=find(merr==min(merr(majority)));
                else
                    ii=find(merr==min(merr(kk)));
                end
            else
                ii=[];
            end

            figure

            if(isempty(ii)==0)
                subplot(2,1,1); %<mo>
                plot(PROFILE_NO(1:n),INTERP_SAL(ii,:),'b*-');
                plot(PROFILE_NO(1:n),mapped_sal(ii,:),'r');
                plot(PROFILE_NO(1:n),cal_INTERP_SAL(ii,:),'g');
                legend('uncal float','mapped salinity','cal float w/err.','location','best');
                mm=find(isfinite(cal_INTERP_SAL(ii,:))==1); ll=PROFILE_NO(1:n); ll=ll(mm); kk=cal_INTERP_SAL(ii,mm); nn=cal_INTERP_SAL_err(ii,mm);
                h=fill([ll,fliplr(ll)],[kk+nn,fliplr([kk-nn])],'g');
                set(h,'EdgeColor','g');
                errorbar(PROFILE_NO(1:n),mapped_sal(ii,:),mapsalerrors(ii,:),'r-')
                plot(PROFILE_NO(1:n),INTERP_SAL(ii,:),'b*-');
                axis([0, max(PROFILE_NO)+1, min([INTERP_SAL(ii,:),cal_INTERP_SAL(ii,:),mapped_sal(ii,:)])-.05, max([INTERP_SAL(ii,:),cal_INTERP_SAL(ii,:),mapped_sal(ii,:)])+.05 ])
                set(gca,'FontSize',12)
                xlabel('float profile number');
                ylabel('salinity (PSS-78)')
                title( strcat(title_floatname, ' salinities with error on \theta = ', num2str(ptlevels(ii)), ' ^{\circ} C' ) );

                %<mo>
                numnan=sum(isnan(INTERP_SAL),2);
                ii=find(numnan==min(numnan));ii=ii(end);
                subplot(2,1,2);
                plot(lo_float_source_data.DATES,INTERP_SAL(ii,:),'b*-');
                plot(lo_float_source_data.DATES,mapped_sal(ii,:),'r');
                plot(lo_float_source_data.DATES,cal_INTERP_SAL(ii,:),'g');
                legend('uncal float','mapped salinity','cal float w/err.','location','best');
                mm=find(isfinite(cal_INTERP_SAL(ii,:))==1); ll=lo_float_source_data.DATES; ll=ll(mm); kk=cal_INTERP_SAL(ii,mm); nn=cal_INTERP_SAL_err(ii,mm);
                h=fill([ll,fliplr(ll)],[kk+nn,fliplr([kk-nn])],'g');
                set(h,'EdgeColor','g');
                errorbar(lo_float_source_data.DATES,mapped_sal(ii,:),mapsalerrors(ii,:),'r-')
                plot(lo_float_source_data.DATES,INTERP_SAL(ii,:),'b*-');
                axis([min(lo_float_source_data.DATES)-.1, max(lo_float_source_data.DATES)+.1, min([INTERP_SAL(ii,:),cal_INTERP_SAL(ii,:),mapped_sal(ii,:)])-.05, max([INTERP_SAL(ii,:),cal_INTERP_SAL(ii,:),mapped_sal(ii,:)])+.05 ])
                xlim=get(gca,'xlim');
                set(gca,'FontSize',12,'xticklabel',datestr(get(gca,'xtick'),12));
                xlabel(['float profile number; max profile=' num2str(PROFILE_NO(end))]);
                ylabel('salinity (PSS-78)')
                title( strcat(title_floatname, ' salinities with error on \theta = ', num2str(ptlevels(ii)), ' ^{\circ} C' ) );

            end

            drawnow
            set(gcf,'papertype','usletter','paperunits','inches','paperorientation','portrait','paperposition',[.25,.75,8,9.5]);
            if pspntb(1)
                print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_9.ps'));
            end
            if pspntb(2)
                print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_9.png'));
            end
            if pspntb(3)
                set(gcf,'paperposition',get(gcf,'paperposition')/3);
                child=get(gcf,'children');
                for c=1:length(child)
                    if isfield(child(c),'title')
                    set(child(c),'fontsize',6);
                    set(get(child(c),'title'),'fontsize',6);
                    set(get(child(c),'ylabel'),'fontsize',6);
                    set(get(child(c),'xlabel'),'fontsize',6);
                    end
                end
                set(gcf,'position',get(gcf,'position')/3);
                print('-dpng ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, 'tb_9.png'));
            end
            close
        end
    end
end