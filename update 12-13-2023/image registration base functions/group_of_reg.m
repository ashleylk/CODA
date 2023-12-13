function [R,rs,xy,amv]=group_of_reg(amv0,arf,iternum0,sz,rf,bb)
% calculates sets of global registrations considering different initialization angles for a pair of greyscale images
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

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