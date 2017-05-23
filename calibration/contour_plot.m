function contour_plot(X,Y,Z,xlim,ylim,clim)
fs='fontsize'; fsn=5;
ok=~(isnan(X) | isnan(Y) | isnan(Z));
if any(ok==1)
    X=X(ok); Y=Y(ok); Z=Z(ok);
    n=64;
    jet0=ones(1,3);jet0(2:n+1,:)=jet(n);
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
                yz=unique([y z],'rows');
                if size(yz,1)~=length(y)
                    warning('dup values');
                end
                y=yz(:,1); z=yz(:,2);
                uuu=find(diff(y)<=0);
                while ~isempty(uuu) %non monotonically increasing; ignore!
                    warning('Non increasing pressure ignored');
                    ok=[1:uuu-1 uuu+1:length(y)];
                    y=y(ok);
                    z=z(ok);
                    uuu=find(diff(y)<=0);
                end
                if length(y)>1
                    zc(i,:)=interp1(y,z,uy); %matrix for contours
                end
                ok=find(diff(y)>thres); %make sure that any depths separated by vertica
                %l gap higher than threshold are not filled
                while ~isempty(ok)
                    y(ok(1)+2:end+1)=y(ok(1)+1:end);
                    y(ok(1)+1)=y(ok(1))+thres/2;
                    z(ok(1)+2:end+1)=z(ok(1)+1:end);
                    z(ok(1)+1)=nan;
                    ok=find(diff(y)>thres);
                end
                if length(y)>1
                    zz(i,:)=interp1(y,z,uy);
                end
            end
            
        end
    end
    zz=zz';
    %clim=minmax(zz);
    clim(isnan(clim))=0;
    if diff(clim)==0 clim=clim+[-.1 .1]; end
    if ux(end)<=20;     incr=1;
    else               incr=10;
    end
    xtick = 0:incr:ux(end);
    mappedzz=(zz-clim(1))/diff(clim)*(n-1)+2;
    mappedzz(isnan(zz))=1;
    yticklabel=min(Z):2:max(Z);
    if length(yticklabel)<5
        yticklabel=min(Z):0.5:max(Z);
        if length(yticklabel)<=5
            yticklabel=min(Z):0.001:max(Z);
            while length(yticklabel)>25
                yticklabel=yticklabel(1:2:end);
            end
        end
    end
    ytick=(yticklabel-clim(1))/diff(clim)*(n-1)+2;

    set(gcf,'colormap',jet0)
    set(gca,'ydir','reverse','xaxislocation','bottom','ylim',ylim,'xlim',xlim,'clim',zlim);
    set(gca,'xcolor','k','xlim',[0 ux(end)]+.5,'ylim',ylim+[-.01 +.01],'xtick',xtick,fs,fsn+3);
    set(get(gca,'xlabel'),'string','Cycle',fs,fsn+5,'fontweight','bold');
    set(get(gca,'ylabel'),'string','Pressure / Pression (dbar)',fs,fsn+5,'fontweight','bold');
    image(ux,uy,mappedzz);
    cb=colorbar('vertical','units','pixels',fs,fsn+2);    
    set(cb,'ytick',ytick,'yticklabel',num2str(yticklabel'));
end