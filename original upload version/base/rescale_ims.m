function rescale_ims

pth='G:\Alicia Braxton\TC_90 PDAC\1x\registered_bad_scale\';
pthTA='G:\Alicia Braxton\TC_90 PDAC\1x\registered_bad_scale\TA\';
% outpth='G:\Alicia Braxton\TC_90 PDAC\1x\rescale\registered\elastic registration\save_warps\';
imlist=dir([pth,'*jpg']);

nums=[198:201 220:223 362:415 416:length(imlist)];
rfs=[1.1115 1.070 1.054 1.219;1 1 1 1];
for kk=1:length(nums)
    im=imread([pth,imlist(nums(kk)).name]);

    RSC=rfs(kk);
    if kk<=4;RSC=rfs(:,1)';end
    if kk>4 && kk<=8;RSC=rfs(:,2)';end
    if kk>8 && kk<=62;RSC=rfs(:,3)';end
    if kk>62;RSC=rfs(:,4)';end
    
    im=imresize(im,RSC);
    
    imwrite(im,[pth,imlist(nums(kk)).name]);
    save([outpth,imlist(nums(kk)).name(1:end-3),'mat'],'RSC');
end


% 362: 1.04


% for kk=198:length(imlist)
%     imrf0=imread([pth,imlist(kk-1).name]);
%     immv0=imread([pth,imlist(kk).name]);
%     [~,immvg,~]=preprocessing(immv0,size(immv0(:,:,1)),[0 0],1);
%     [~,imrfg,~]=preprocessing(imrf0,size(imrf0(:,:,1)),[0 0],1);
%     
%     tic;tform=imregcorr(immvg,imrfg);toc;
%     Rfixed = imref2d(size(imrfg));
%     im2 = imwarp(immvg,tform,'OutputView',Rfixed);
%     
%     figure,
%         subplot(1,2,1),imshowpair(imrfg,immvg);
%         subplot(1,2,2),imshowpair(imrfg,im2);
% end


%     RSC=rfs(kk);
%     if kk<=4;RSC=rfs(1);end
%     if kk>4 && kk<=8;RSC=rfs(2);end
%     if kk>8 && kk<=62;RSC=rfs(3);end
%     if kk>62;RSC=rfs(4);end
%     
%     im=imresize(im,RSC);
%     
%     imwrite(im,[pth,imlist(nums(kk)).name]);
%     save([outpth,imlist(nums(kk)).name(1:end-3),'mat'],'RSC');
% end
% 
% 
% 
% 
% 
% nums=[198:201 220:223 362:415 416:length(imlist)];
% rfs=[1.113 1.070 1.054 1.219];
% for kk=1:length(nums)
%     im=imread([pth,imlist(nums(kk)).name]);
% 
%     RSC=rfs(kk);
%     if kk<=4;RSC=rfs(1);end
%     if kk>4 && kk<=8;RSC=rfs(2);end
%     if kk>8 && kk<=62;RSC=rfs(3);end
%     if kk>62;RSC=rfs(4);end
%     
%     im=imresize(im,RSC);
%     
%     imwrite(im,[pth,imlist(nums(kk)).name]);
%     save([outpth,imlist(nums(kk)).name(1:end-3),'mat'],'RSC');
% end