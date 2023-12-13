function [X,Y,imout,RR]=reg_ims_ELS(amv0,arf0,rf,v)
if ~exist('v','var');v=0;imout=[];RR=[];end
    arf=imresize(arf0,1/rf);
    amv=imresize(amv0,1/rf);
    try xy1=calculate_transform(arf,amv);catch;xy1=[0 0];end
    try xy2=calculate_transform(amv,arf);catch;xy2=[0 0];end
    xyt=mean([xy1;-xy2]);
    
    X=-(xyt(1)*rf);
    Y=-(xyt(2)*rf);
    
    if v
        imout=imtranslate(amv0,[-X -Y]);
        a=imout(imout>0 & arf0>0);
        b=arf0(imout>0 & arf0>0);
        RR=corr2(a,b);
    end
end