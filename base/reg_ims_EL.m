function [amv,X,Y]=reg_ims_ELS(amv,arf,count,rf,modeg,mkim)
    amv0=amv;
    amv=imresize(amv,1/rf);
    arf=imresize(arf,1/rf);
    b0=single(arf);
    mm=0;
    
    % iterate 'count' times to calculate registration on resized, blurred image
    xyt=[0; 0];
    
    if count==1
        bmv=single(amv);
        try xyt=anl_im_dR_aNE2(b0,bmv);catch;xyt=[0 0];end
    else
        for kk=1:count          
            bmv=single(amv);
            try xy=anl_im_dR_aNE2(b0,bmv);catch;xy=[0 0];end

            % update total xy
            xyt=xyt+([xy(1); xy(2)]*rf);                                           % translation

            % update registration image 
            amv=imtranslate(amv0,xyt'/rf,'OutputView','same');
            amv(amv==0)=mm;

            if sqrt(xy(1)^2+xy(2)^2)<0.5;break;end
        end
    end
% apply calculated registration to fullscale image 
% (account for translation 'sz' due to cropping tissue from full images)
xyt=round(xyt);
X=-xyt(1);
Y=-xyt(2);

if mkim
    tform=affine2d([1 0 0;0 1 0;xyt(1) xyt(2) 1]);
    Rin=imref2d(size(amv0));
    mx=mean(Rin.XWorldLimits);
    my=mean(Rin.YWorldLimits);
    Rin.XWorldLimits = Rin.XWorldLimits-mx;
    Rin.YWorldLimits = Rin.YWorldLimits-my; 
    % register
    amv=imwarp(amv0,Rin,tform,'Outputview',Rin,'Fillvalues',modeg);
end
end