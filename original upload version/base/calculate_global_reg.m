function [imout,tform,cent,f,Rout]=calculate_global_reg(imrf,immv,rf,iternum,IHC,bb)
if ~exist('bb','var');bb=0.9;end
% imrf == reference image
% immv == moving image
% szz == max size of images in stack
% rf == reduce images by _ times
% count == number of iterations of registration code
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
    if R<0.8
        disp('try flipping image')
        amv2=amv(end:-1:1,:,:);
        [R2,rs2,xy2,amv2out]=group_of_reg(amv2,arf,iternum0,sz,rf,bb);
        if R2>R;rs=rs2;xy=xy2;f=1;amv=amv2;end
%         figure(13),imshowpair(arf,amv2out),title(num2str(round(R2*100)))
    end
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

function [R,rs,xy,amv]=group_of_reg(amv0,arf,iternum0,sz,rf,bb)
    if ~exist('bb','var');bb=0.9;end
    T=[-2 177 87 268 -1 88 269 178 -7:2:7 179:183 89:93 270:272];
    R=0.2;
    rs=0;
    xy=0;
    aa=arf==0;ab=amv0==0;
    arf=double(arf);amv0=double(amv0);
    arf=(arf-mean(arf(:)))/std(amv0(:));
    amv0=(amv0-mean(amv0(:)))/std(amv0(:));
    arf=arf-min(arf(:));arf(aa==1)=0;
    amv0=amv0-min(amv0(:));amv(ab==1)=0;
    amv=amv0;
    RR0=sum(amv(:)>0) + sum(arf(:)>0);
    for kp=1:length(T)
        try 
            [~,amv1,rs1,xy1,RR]=reg_ims_com(amv0,arf,iternum0,sz,rf,T(kp),[0; 0],1);
            if RR~=0;aa=double(arf>0)+double(amv1>0);RR=sum(aa(:)==2)/sum(aa(:)>0);end
        catch
            disp('catch')
            RR=0;
        end
        
        %figure(8),imshowpair(arf,amv1),title(num2str(RR))
        if RR>R;R=RR;rs=rs1;xy=xy1;amv=amv1;end
        if R>bb && kp>16;break;end
        %disp([RR R bb])
    end
end