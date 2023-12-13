% pth='G:\Alicia Braxton\TC_90 PDAC\1x\';
pth='G:\Alicia Braxton\TC_90 PDAC\1x\registered_bad_scale\';
pthTA='G:\Alicia Braxton\TC_90 PDAC\1x\registered_bad_scale\TA\';
imlist=dir([pth,'*jpg']);
imlistTA=dir([pthTA,'*tif']);
li=length(imlist);

ta=zeros([1 li]);
for kk=1:li
    im=imread([pth,imlist(kk).name]);
    TA=find_tissue_area(im);
    ta(kk)=sum(TA(:));
    if kk==1;ta0=ta(kk);end
    fprintf('image %0.0f of %0.0f. TA=%0.0f. change=%0.2f\n',...
        kk,li,ta(kk),ta(kk)/ta0);
    ta0=ta(kk);
    
    imwrite(TA,[pth,'TA\',imlist(kk).name]);
    
    
end
