function plot_3D_tiss(volbody,map,sx,sz,FA,crop,I,shiftxyz)
% volbody = 3D binary matrix of object
% map = rgb color of object (for example, [1 0 0] = red, [0 1 0]=green, [0 0 1]=blue)
% sx = xy resolution (um/pixel)
% sz = z resolution (um/pixel)
    if ~exist('sx','var');sx=1;end
    if ~exist('sz','var');sz=1;end
    if ~exist('crop','var');crop=1;end
    if ~exist('map','var');map=[0 0 1];end
    if ~exist('FA','var');FA=0.8;end %opacity 1 .5 half invisible test
    if ~exist('shiftxyz','var');shiftxyz=[0 0 0];end
    ss=0;caps=1;
    if exist('I','var') && ~isempty(I);plotim=1;else;plotim=0;end
    if max(map(:))>1;map=double(map)/255;end


    if crop
        if plotim;I=imresize(I,size(volbody(:,:,1)));end
        
        tmp=squeeze(sum(sum(volbody,1),2))>0;
        zz=[find(tmp>0,1,'first') find(tmp>0,1,'last')];
        tmp=sum(volbody,3);
        yy=[find(sum(tmp,1)>0,1,'first') find(sum(tmp,1)>0,1,'last')];
        xx=[find(sum(tmp,2)>0,1,'first') find(sum(tmp,2)>0,1,'last')];
        shiftxyz(1)=shiftxyz(1)+yy(1)-1;
        shiftxyz(2)=shiftxyz(2)+xx(1)-1;
        shiftxyz(3)=shiftxyz(3)+zz(1)-1;
        volbody=volbody(xx(1):xx(2),yy(1):yy(2),zz(1):zz(2));
        
        if plotim;I=I(xx(1):xx(2),yy(1):yy(2),:);end
    end
    
    if plotim
        imagesc([0 size(volbody,2)*sx/10000], [0 size(volbody,1)*sx/10000],I); %plotHE 8bit
    end
    
    vt=volbody(:,:,1);
    vb=volbody(:,:,end);
    szz=size(volbody);

    if sx==1 && sz==1
        patch(isosurface(volbody),'FaceColor',map,'EdgeColor','none','FaceAlpha',FA);clearvars volbody
        voltop=zeros(szz);voltop(:,:,1)=vt;
        patch(isosurface(voltop),'FaceColor',map,'EdgeColor','none','FaceAlpha',FA);clearvars voltop
        volbot=zeros(szz);volbot(:,:,end)=vb;
        patch(isosurface(volbot),'FaceColor',map,'EdgeColor','none','FaceAlpha',FA);clearvars volbot
    else
        [xg,yg,zg]=meshgrid(1:size(volbody,2),1:size(volbody,1),1:size(volbody,3));
        xg=(xg+shiftxyz(1))*sx/10000;
        yg=(yg+shiftxyz(2))*sx/10000;
        zg=(zg+shiftxyz(3))*sz/10000;
        patch(isosurface(xg,yg,zg,volbody),'FaceColor',map,'EdgeColor','none','FaceAlpha',FA);clearvars volbody
        
        if caps
            voltop=zeros(szz);voltop(:,:,1)=vt;
            patch(isosurface(xg,yg,zg,voltop),'FaceColor',map,'EdgeColor','none','FaceAlpha',FA);clearvars voltop
            volbot=zeros(szz);volbot(:,:,end)=vb;
            patch(isosurface(xg,yg,zg,volbot),'FaceColor',map,'EdgeColor','none','FaceAlpha',FA);clearvars volbot
        end
        
        if ss
            volss=zeros(szz);volss(1,:,:)=volbody(1,:,:);
            patch(isosurface(xg,yg,zg,volss),'FaceColor',map,'EdgeColor','none','FaceAlpha',FA);clearvars voltop
            
            volss=zeros(szz);volss(end,:,:)=volbody(end,:,:);
            patch(isosurface(xg,yg,zg,volss),'FaceColor',map,'EdgeColor','none','FaceAlpha',FA);clearvars voltop
            
            volss=zeros(szz);volss(:,1,:)=volbody(:,1,:);
            patch(isosurface(xg,yg,zg,volss),'FaceColor',map,'EdgeColor','none','FaceAlpha',FA);clearvars voltop
            
            volss=zeros(szz);volss(:,end,:)=volbody(:,end,:);
            patch(isosurface(xg,yg,zg,volss),'FaceColor',map,'EdgeColor','none','FaceAlpha',FA);clearvars voltop
        end
    end
    plot_settings(1);
%     
%     if sx==1 && sz==1
%         xlim([0 size(volbody,2)])
%         ylim([0 size(volbody,1)])
%         zlim([0 size(volbody,3)])
%     else
%         xlim([min(xg(:)) max(xg(:))])
%         ylim([min(yg(:)) max(yg(:))])
%         zlim([min(zg(:)) max(zg(:))])
%     end
end

%  
% cmap=[121 248 252;...   % 1 islet
%     0    0    255;...   % 2 duct
%     80 237 80;...       % 3 blood vessel
%     255  255  0;...     % 4 fat
%     149 35  184;...     % 5 acinus
%     255 194 245;...     % 6 connective tissue
%     255 255 255;...     % 7 whitespace
%     255  0  0;...       % 8 PanIN
%     240 159 10;...      % 9 PDAC 
%     0 0 0]/255;         %10 endothelium
% cc=cmap(5,:)*0.5+cmap(6,:)*0.5;




