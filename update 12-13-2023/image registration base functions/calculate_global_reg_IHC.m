function [imout,tform,cent,f,Rout]=calculate_global_reg_IHC(imrf,immv,rf,iternum,IHC)
if IHC==1;bb=0.8;else;bb=0.9;end
% calculates global registration of a pair of greyscale, downsampled histological images containing IHC stained data.
% imrf == reference image
% immv == moving image
% szz == max size of images in stack
% rf == reduce images by _ times
% count == number of iterations of registration code
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

    % pre-registration image processing
    amv=imresize(immv,1/rf);amv=imgaussfilt(amv,2);
    arf=imresize(imrf,1/rf);arf=imgaussfilt(arf,2);
    sz=[0 0];cent=[0 0];
    if IHC>0;amv=imadjust(amv);arf=imadjust(arf);end
    
    % calculate registration, flipping image if necessary
    iternum0=2;
    [R,rs,xy,amv1out]=group_of_reg(amv,arf,iternum0,sz,rf,bb);
    %figure(9),imshowpair(amv1out,arf)
    f=0;
%     figure(12),imshowpair(arf,amv1out),title(num2str(round(R*100)))
    ct=0.8;

    [tform,amvout,~,~,Rout]=reg_ims_com(amv,arf,iternum-iternum0,sz,rf,rs,xy,0);
    aa=double(arf>0)+double(amvout>0);
    Rout=sum(aa(:)==2)/sum(aa(:)>0);
    %figure(9),imshowpair(amvout,arf)
    
    % create output image
    Rin=imref2d(size(immv));
    if sum(abs(cent))==0
      mx=mean(Rin.XWorldLimits);
      my=mean(Rin.YWorldLimits);
      cent=[mx my];
    end
    Rin.XWorldLimits = Rin.XWorldLimits-cent(1);
    Rin.YWorldLimits = Rin.YWorldLimits-cent(2);

    if f==1
        immv=immv(end:-1:1,:,:);
    end
    
    % register
    imout=imwarp(immv,Rin,tform,'nearest','Outputview',Rin,'Fillvalues',0);
    %figure,imshowpair(arf,amvout)
end

