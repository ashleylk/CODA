function [D,xgg,ygg,xx,yy]=calculate_elastic_registration(imrfR,immvR,TArf,TAmv,sz,bf,di,cutoff)
% Iterative calculation of registration translation on small tiles for determination of nonlinear alignment of globally aligned images.
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if ~exist('cutoff','var');cutoff=0.15;end
    cc=10;cc2=cc+1;
    szim=size(immvR);
    m=(sz-1)/2+1;

    immvR=double(padarray(immvR,[bf bf],mode(immvR(:))));immvR=imgaussfilt(immvR,3);
    imrfR=double(padarray(imrfR,[bf bf],mode(imrfR(:))));imrfR=imgaussfilt(imrfR,3);
    TAmv=padarray(TAmv,[bf bf],0);
    TArf=padarray(TArf,[bf bf],0);

    % make grid for registration points
    n1=randi(round(di/2),1)+bf+m;
    n2=randi(round(di/2),1)+bf+m;
    [x,y]=meshgrid(n1:di:size(immvR,2)-m-bf,n2:di:size(immvR,1)-m-bf);
    x=x(:);y=y(:);
    
    % get percentage of tissue in each registration ROI
    checkS=zeros(size(x));
    numb=200;
    for b=1:numb:size(x)
        b2=min([b+numb-1 length(x)]);
        ii=getImLocalWindowInd_rf([x(b:b2) y(b:b2)],size(TAmv),m-1,1);
        
        imcheck=reshape(permute(TAmv(ii),[2 1]),[sz sz size(ii,1)]);
        imcheck2=zeros(size(imcheck));
        imcheck2(cc2:end-cc,cc2:end-cc,:)=imcheck(cc2:end-cc,cc2:end-cc,:);
        mvS=squeeze(sum(sum(imcheck2,1),2)); % indices of image tiles with tissue in them
        
        imcheck=reshape(permute(TArf(ii),[2 1]),[sz sz size(ii,1)]);
        rfS=squeeze(sum(sum(imcheck,1),2)); % indices of image tiles with tissue in them
        
        checkS(b:b2)=min([mvS rfS],[],2);
    end
    clearvars ii imcheck imcheck2
    checkS=checkS/(sz^2);
    
    yg=(y-min(y))/di+1;
    xg=(x-min(x))/di+1;
    xgg0=ones([length(unique(y)) length(unique(x))])*-5000;
    ygg0=ones([length(unique(y)) length(unique(x))])*-5000;
    
    for kk=find(checkS>cutoff)'
        % setup small tiles
        ii=getImLocalWindowInd_rf([x(kk) y(kk)],size(TAmv),m-1,1);ii(ii==-1)=1;
        immvS=immvR(ii);imrfS=imrfR(ii);
        immvS=reshape(permute(immvS,[2 1]),[sz sz]);
        imrfS=reshape(permute(imrfS,[2 1]),[sz sz]);
        
        % calculate registration for tiles kk
        [X,Y,imoutS]=reg_ims_ELS(immvS,imrfS,2,1);

%         [X,Y,imoutS,RS]=reg_ims_ELS(immvS,imrfS,2,1);
%         immvS2=zeros(size(immvS));immvS2(cc2:end-cc,cc2:end-cc,:)=immvS(cc2:end-cc,cc2:end-cc,:);
%         a=immvS2(immvS2>0 & imrfS>0);b=imrfS(immvS2>0 & imrfS>0);R0=corr2(a,b);RR=[R0 RS];
%          if max(RR)==RS;X=XS;Y=YS;else;X=-5000;Y=-5000;end
%         figure(38),
%             subplot(1,2,1),imshowpair(imrfS,immvS)%,title(R0/checkS(kk))
%             subplot(1,2,2),imshowpair(imrfS,imoutS)%,title(RS/checkS(kk))
        xgg0(yg(kk),xg(kk))=X;
        ygg0(yg(kk),xg(kk))=Y;
    end
    % smooth registration grid and make interpolated displacement map
    if max(szim)>2000;szimout=round(szim/5);x=x/5;y=y/5;bf=bf/5;else;szimout=szim;end
    [D,xgg,ygg,xx,yy]=make_final_grids(xgg0,ygg0,bf,x,y,szimout);
    
%     im=imwarp(immvR,D);%figure,imshowpair(im,imrfR)
%     figure(17);
%             subplot(1,2,1),imshowpair(imrfR,immvR)
%             subplot(1,2,2),imshowpair(imrfR,im)
%             ha=get(gcf,'children');linkaxes(ha);
end
