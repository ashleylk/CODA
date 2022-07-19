function [CVS,tiss_area]=make_rgb_kmeans_nw(im,knum,v)
% im: image (type uint8)
% knum: number of pixels to use for kmeans
% v: if true, visualize colors chosen for deconvolution

% uses kmeans to detect bluest and pinkest groups in H&E image
    
    if nargin==1
        knum=200000;
        v=0;
    elseif nargin==2
        v=0;
    end

    im=im2single(im);
    imr0=im(:,:,1);imr=imgaussfilt(imr0,1);
    img0=im(:,:,2);img=imgaussfilt(img0,1);
    imb0=im(:,:,3);imb=imgaussfilt(imb0,1);
    Cw=[mode(imr0(:)) mode(img0(:)) mode(imb0(:))];
    %meshlist=cat(2,imr(:),img(:),imb(:));
    
    
    % make list of nonwhite pixels in tissue image
    tiss_area=std(cat(3,imr0,img0,imb0),[],3);
    tiss_area=tiss_area>0.03 & tiss_area<0.35; % remove white and random bright pixels
    meshlist=cat(2,imr(tiss_area),img(tiss_area),imb(tiss_area));
    
    % classify subset of tissue area into 255 groups
    tic;
    if knum>size(meshlist,1)
        knum=size(meshlist,1);
    end
    kk=randperm(size(meshlist,1),knum);
    meshlist=meshlist(kk,:);
    [idx,C]=kmeans(meshlist,1000);
    clearvars meshlist
    
    % delete 50 classes with fewest pixels
    N=histcounts(idx,1000);
    [~,s]=sort(N);
    C=C(s,:);
    C=C(26:end,:);
    
    % delete classes that are too close to greyscale
    [~,s]=sort(sum(C,2));
    C=C(s,:);
    Cs=std(C,[],2);
   
    % define background class
    bg=-log((Cw*255+1)./256);
    bg=bg/norm(bg);
    C=C(Cs>0.1,:);
    
    % find bluest class (average of 100 darkest classes):
    [~,s]=sort(sum(C(:,3),2));
    Cb=C(s,:);
    ii=Cb(:,3)>Cb(:,1);
    Cb=Cb(ii,:);
    num=min([size(Cb,1)/5 75]);
    bluest0=mean(Cb(1:num,:)); % 75
    bluest=-log((bluest0*255+1)./256);
    bluest=bluest/norm(bluest);
    
    % find brownest class (average of 100 lightest classes):
    [~,s]=sort(sum(C(:,1),2));
    Cr=C(s,:);
    ii=Cr(:,1)>Cr(:,3);
    if isempty(ii) || sum(ii)<10
        b=Cr(:,1)./Cr(:,3);
        [~,s]=sort(sum(b,2));
        Cr=Cr(s,:);
    else
        Cr=Cr(ii,:);
    end
    
    num=min([round(size(Cr,1)/5) 75]);
    pinkest0=mean(Cr(end-num:end,:));
    pinkest=-log((pinkest0*255+1)./256);
    pinkest=pinkest/norm(pinkest);
    
    CVS=[bluest;pinkest;[1 1 1]-mean([bluest;pinkest])];
    %CVS=[bluest;pinkest;bg];
    if v % visualize chosen colors and colormap
        cmap=cat(3,C(:,1),C(:,2),C(:,3));
        cmap=repmat(cmap,[1 100]);
        figure(1),imshow(cmap),set(gcf,'color','k'),title('color map')

        tmp1=permute(bluest0,[1 3 2]);
        tmp2=permute(pinkest0,[1 3 2]);
        tmp3=permute(Cw,[1 3 2]);
        figure(2),
            subplot(1,3,1),imshow(repmat(tmp1,[50 50 1])),set(gcf,'color','k')
            subplot(1,3,2),imshow(repmat(tmp2,[50 50 1])),set(gcf,'color','k')
            subplot(1,3,3),imshow(repmat(tmp3,[50 50 1])),set(gcf,'color','k')
%         pause
%         close all
        disp(CVS)
    end
end



    %Cp=C(sum(C,2)>2,:);
    %Cp=C(C(:,1)>C(:,3),:); % red channel greater than blue channel
%     Cp=C;
%     Cpink=(Cp(:,1)+Cp(:,3)/2)./Cp(:,2);
%     ipink=find(Cpink==max(Cpink));
%     pinkest0=Cp(ipink,:);
%     Cp=C(end-19:end,:);
%     [~,s]=sort(Cp(:,1));
%     pinkest0=Cp(s,:);
%     pinkest0=mean(pinkest0(end-9:end,:)); % take 10 of the lightest 20 classes with most red