function [tform,amv,rsft,xyt,RR]=reg_ims_com(amv0,arf,count,sz,rf,deg0,xy0,r,th)
    tform=[];rsft=0;xyt=[0; 0];RR=0;amv=amv0;
    mm=mode(amv(:));mmr=mode(arf(:));
%     arf=padarray(arf,[50 50],mmr,'both');
%     amv=padarray(amv,[50 50],mm,'both');
    
    if nargin<10
        theta=-90:0.5:90;
        thetaout=2;
    else
        theta=th{1};
        thetaout=th{2};
    end
    if nargin<8;r=0;end
    if nargin<7;xy0=[0; 0];end
    if nargin<6;deg0=0;end
    
    brf=single(arf);
    
    xyt=[0; 0];
    
    rsft=zeros([1 count+1]);
    rsft(1)=deg0;
    amvr=imrotate(amv0,sum(rsft),'crop');
    if sum(amvr(:))==0;rsft=sum(rsft);return;end
    
    % first translation dictated by center of mass
    if r
        % find center of mass of images
        amv2=bpassW(amvr,2,50);amv2=amv2>0;
        arf2=bpassW(arf,2,50);arf2=arf2>0;
        cx=sum(amv2);cy=sum(amv2,2);
        cx=cumsum(cx);cy=cumsum(cy);
        cmamv=[find(cx>cx(end)/2,1) find(cy>cy(end)/2,1)];
        cx=sum(arf2);cy=sum(arf2,2);
        cx=cumsum(cx);cy=cumsum(cy);
        cmarf=[find(cx>cx(end)/2,1) find(cy>cy(end)/2,1)];
        xy=cmarf-cmamv;
        xyt=[xy(1); xy(2)]*rf;
    end
    
    xyt=xyt+xy0;
    amv=imtranslate(amvr,xyt'/rf,'OutputView','same');
    a=arf>0;
    RR0=corr2(amv(a),arf(a));
    
    % iterate 'count' times to achieve sufficient global registration on resized, blurred image
    for kk=1:count 
        bmv=single(amv);

        % use radon for rotational registration
        R0 = radon(arf, theta);
        Rn = radon(amv, theta);
        R0=bpassW(R0,1,3);
        Rn=bpassW(Rn,1,3);

        try rsf1=calculate_transform(R0,Rn);catch;rsf1=0;end
        rsf=rsf1(1)/thetaout;

        % rotate image then calculate translational registration
        bmvr=imrotate(bmv,rsf(1),'crop');
        bmvr(bmvr==0)=mm;

        try xy1=calculate_transform(brf,bmvr);catch;xy1=[0 0];end
        try xy2=calculate_transform(bmvr,brf);catch;xy2=[0 0];end
        xy=mean([xy1;-xy2]);

        % keep old transform in case update is bad
        rsft0=rsft;
        xyt0=xyt;
        
        % update total rsf and xy
        rsft(kk+1)=rsf;
        if rsf>0 % update rotation
            xyt=[cosd(rsf) -sind(rsf);sind(rsf) cosd(rsf)]*xyt; % clockwise rotation
        else
            xyt=[cosd(rsf) sind(rsf);-sind(rsf) cosd(rsf)]*xyt; % counterclockwise rotation
        end
        xyt=xyt+([xy(1); xy(2)]*rf);                             % translation
        
        % update registration image 
        amv=imrotate(amv0,sum(rsft),'crop');
        amv=imtranslate(amv,xyt'/rf,'OutputView','same');
        amv(amv==0)=mm;
        
        a=arf>0;
        RR=corr2(amv(a),arf(a));
        if RR+0.02<RR0 && count>2 % if iteration hasn't improved correlation of images, then stop
            rsft=rsft0;
            xyt=xyt0;
            amv=imrotate(amv0,sum(rsft),'crop');
            amv=imtranslate(amv,xyt'/rf,'OutputView','same');
            amv(amv==0)=mm;
            RR=corr2(amv(a),arf(a));
            break;
        end
        
        x1=round(size(amv,2)/2); % maximum distance a point in the image moves
        y1=round(size(amv,1)/2);
        x2=x1*cosd(rsft(kk+1))-y1*sind(rsft(kk+1))+xy(2)-x1;
        y2=x1*sind(rsft(kk+1))+ y1*cosd(rsft(kk+1))+xy(1)-y1;
        rff=sqrt(x2^2+y2^2);
        if rff<0.75 || RR>0.9
            break
        end
        
    end
    % apply calculated registration to fullscale image 
    % (account for translation 'sz' due to cropping tissue from full images)
    rsft=sum(rsft);
    tform=affine2d([cosd(rsft) -sind(rsft) 0;sind(rsft) cosd(rsft) 0;xyt(1)+sz(1) xyt(2)+sz(2) 1]);
end