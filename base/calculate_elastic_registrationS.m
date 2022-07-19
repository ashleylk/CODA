function [D,xgg,ygg,xx,yy]=calculate_elastic_registrationS(imrfR,immvR,TArf,TAmv,sz,bf,di)
    szim=size(immvR);
    m=(sz-1)/2+1;
    P1=sz+bf+bf;
    immvR=double(padarray(immvR,[bf bf],mode(immvR(:))));
    imrfR=double(padarray(imrfR,[bf bf],mode(imrfR(:))));
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
        %imcheck2=zeros(size(imcheck));imcheck2(36:end-35,36:end-35,:)=imcheck(36:end-35,36:end-35,:);mvS2=squeeze(sum(sum(imcheck2,1),2));
        mvS=squeeze(sum(sum(imcheck,1),2)); % indices of image tiles with tissue in them
        
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
    cutoff=0.4; % register if image tiles are >=15% tissue
    for kk=find(checkS>cutoff)'
        % setup small tiles
        ii=getImLocalWindowInd_rf([x(kk) y(kk)],size(TAmv),m-1,1);ii(ii==-1)=1;
        immvS=immvR(ii);imrfS=imrfR(ii);
        immvS=reshape(permute(immvS,[2 1]),[sz sz size(immvS,1)]);
        imrfS=reshape(permute(imrfS,[2 1]),[sz sz size(imrfS,1)]);
        
        % calculate registration for tiles kk
        %immvS2=zeros(size(immvS));immvS2(36:end-35,36:end-35,:)=immvS(36:end-35,36:end-35,:);[XS,YS,imoutS,RS]=reg_ims_ELS(immvS2,imrfS,2);a=immvS2(immvS2>0 & imrfS>0);b=imrfS(immvS2>0 & imrfS>0);R0=corr2(a,b);
        [XS,YS,imoutS,RS]=reg_ims_ELS(immvS,imrfS,2);
        a=immvS(immvS>0 & imrfS>0);b=imrfS(immvS>0 & imrfS>0);R0=corr2(a,b);
        RR=[R0 RS];
        if max(RR)==RS;X=XS;Y=YS;else;X=-5000;Y=-5000;end
%         figure(38),
%             subplot(1,2,1),imshowpair(imrfS,immvS),title(R0/checkS(kk))
%             subplot(1,2,2),imshowpair(imrfS,imoutS),title(RS/checkS(kk))
        xgg0(yg(kk),xg(kk))=X;
        ygg0(yg(kk),xg(kk))=Y;
    end
    % smooth registration grid and make interpolated displacement map
    [D,xgg,ygg,xx,yy]=make_final_grids(xgg0,ygg0,bf,x,y,szim);
    im=imwarp(immvR,D);%figure,imshowpair(im,imrfR)
    figure(17);
            subplot(1,2,1),imshowpair(imrfR,immvR)
            subplot(1,2,2),imshowpair(imrfR,im)
            ha=get(gcf,'children');linkaxes(ha);
end


% if max([abs(X) abs(Y)])>40
%     imcheck=imtranslate(tmpmv,[-X -Y]);
%     a=tmpmv(tmpmv>0 & tmprf>0);b=tmprf(tmpmv>0 & tmprf>0);R0=corr2(a,b);
%     a=imcheck(imcheck>0 & tmprf>0);b=tmprf(imcheck>0 & tmprf>0);RR=corr2(a,b);
%     if R0>RR
%         X=-5000;Y=-5000;disp([R0 RR]);
%     end
% end


%             figure(92),
%                 subplot(1,2,1),imshowpair(tmprf,tmpmv),title(num2str(C0(yg(kk),xg(kk))))
%                 subplot(1,2,2),imshowpair(tmprf,mv20),title(num2str(CR(yg(kk),xg(kk))))




% P1=sz+bf+bf;
% checkS=zeros(size(x));
% checkL=zeros(size(x));
% numb=200;
% for b=1:numb:size(x)
%     b2=min([b+numb-1 length(x)]);
%     ii=getImLocalWindowInd_rf([x(b:b2) y(b:b2)],size(TAmv),m-1+bf,1);
% 
%     imcheck=permute(TAmv(ii),[2 1]);
%     imcheck=reshape(imcheck,[P1 P1 size(imcheck,2)]);
%     mvS=squeeze(sum(sum(imcheck(bf+1:bf+sz,bf+1:bf+sz,:),1),2)); % indices of image tiles with tissue in them
%     mvL=squeeze(sum(sum(imcheck,1),2)); % indices of image tiles with tissue in them
% 
%     imcheck=permute(TArf(ii),[2 1]);
%     imcheck=reshape(imcheck,[P1 P1 size(imcheck,2)]);
%     rfS=squeeze(sum(sum(imcheck(bf+1:bf+sz,bf+1:bf+sz,:),1),2)); % indices of image tiles with tissue in them
%     rfL=squeeze(sum(sum(imcheck,1),2)); % indices of image tiles with tissue in them
% 
%     checkS(b:b2)=min([mvS rfS],[],2);
%     checkL(b:b2)=min([mvL rfL],[],2);
% end
% clearvars ii imcheck
% checkS=checkS/(sz^2);
% checkL=checkL/(P1^2);

