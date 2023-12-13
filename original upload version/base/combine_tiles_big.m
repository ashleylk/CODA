function numann=combine_tiles_big(numann0,numann,imlist,nblack,pthDL,outpth,sxy,EE,stile,nbg)
if ~exist('EE','var');EE=0;end
if ~exist('nbg','var');nbg=0;end
if ~exist('stile','var');stile=10000;end
cc=300;
stile=stile+cc*2;

% define folder locations
outpthim=[pthDL,outpth,'im\'];
outpthlabel=[pthDL,outpth,'label\'];
outpthbg=[pthDL,outpth,'big_tiles\'];
mkdir(outpthim);mkdir(outpthlabel);mkdir(outpthbg);
imlistck=dir([outpthim,'*tif']);
nm0=length(imlistck)+1;

% create very large blank images
imH=ones([stile stile 3])*nbg;
imT=zeros([stile stile]);
imT2=imT(cc+1:end-cc,cc+1:end-cc,:);
nL=numel(imT2);clearvars imT2
ct=zeros([1 size(numann,2)]);
sf=sum(ct)/nL;

count=1;
cutoff=0.6;
tcount=1;
tps=find(sum(numann0)==0);
minn=50;maxx=500000;
while sf<cutoff
    % identify type of tissue to load
    if rem(count,30)==0 && EE
        type=tcount;tcount=rem(tcount,length(ct))+1;
        kpall=1;
    else
        type=find(sum(ct,1)==min(sum(ct,1)));type=type(1);
        kpall=0;
    end
    num=find(numann(:,type)>minn & numann(:,type)<maxx);
    % reload annotations if necessary
    if isempty(num)
        disp(['RELOAD TYPE: ',num2str(type)])
        numann(:,type)=numann0(:,type);
        num=find(numann(:,type)>minn & numann(:,type)<maxx);
    end
    % randomly choose 1 of available annotations
    num=num(randperm(length(num),1))';

    % load annotation and mask
    imnm=imlist(num).name;
    pthim=[imlist(num).folder,'\'];
    pthlabel=[pthim(1:end-3),'label\'];
    TA=double(imread([pthlabel,imnm]));
    im=double(imread([pthim,imnm]));

    % keep only needed annotation classes
    if rem(count,2)==1;doaug=1;else;doaug=0;end
    [im,TA,kp]=edit_annotation_tiles(im,TA,doaug,type,ct,size(imT,1),kpall);
    numann(num,kp)=0;
    fx=TA~=0;if sum(fx(:))<30;disp('not enough tissue');continue;end

    % add annotation to large tile
    t=0;szz=size(TA)-1;ctt=1;
    while t==0
        t=1;
        pi=randi(numel(imT));
        [y,x]=ind2sub(size(imT),pi);
        try 
            tmpT=imT(x:x+szz(1),y:y+szz(2));
            fill0=sum(tmpT(:)~=0);
            tmpT(fx)=TA(fx);
            fill=sum(tmpT(:)~=0);
            percadd=(fill-fill0)/numel(tmpT); % (percent tile full - old percent tile full) / size tile
            if percadd<0.4 && ctt<5;t=0;ctt=ctt+1;end
        catch
            t=0;
        end
    end
    tmpH=imH(x:x+szz(1),y:y+szz(2),:);
    tmpH(cat(3,fx,fx,fx))=im(cat(3,fx,fx,fx));
    imT(x:x+szz(1),y:y+szz(2))=tmpT;
    imH(x:x+szz(1),y:y+szz(2),:)=tmpH;

    % update total count
    if  mod(count,500)==0 || sf>cutoff
        ct=histcounts(imT(:),0:size(numann,2)+1);
        ct=ct(2:end);ct(tps)=Inf;
        disp([round(sf*100) ct/min(ct)])
    else
        ct2=histcounts(tmpT(:),0:size(numann,2)+1);ct=ct+ct2(2:end);
    end
    ct2=ct;ct2(ct2==Inf)=0;sf=sum(ct2)/nL;

    count=count+1;
end

% cut edges off tile
imH=uint8(imH(cc+1:end-cc,cc+1:end-cc,:));
imT=uint8(imT(cc+1:end-cc,cc+1:end-cc,:));
imT(imT==0)=nblack;

% save cutouts to outpth
sz=size(imH);
for s1=1:sxy:sz(1)
    for s2=1:sxy:sz(2)
        try
            imHtmp=imH(s1:s1+sxy-1,s2:s2+sxy-1,:);
            imTtmp=imT(s1:s1+sxy-1,s2:s2+sxy-1,:);
        catch
            continue
        end
        imwrite(imHtmp,[outpthim,num2str(nm0),'.tif']);
        imwrite(imTtmp,[outpthlabel,num2str(nm0),'.tif']);
        
        nm0=nm0+1;
    end
end

% save large tiles
nm1=dir([outpthbg,'*tif']);nm1=length(nm1)/2+1;
imwrite(imH,[outpthbg,'HE_tile_',num2str(nm1),'.tif']);
imwrite(imT,[outpthbg,'label_tile_',num2str(nm1),'.tif']);

end

function [im,TA,kpout]=edit_annotation_tiles(im,TA,doaug,type,ct,sT,kpall)
% makes sure annotation distribution doesn't vary by more than 1%
	if doaug
        [im,TA]=random_augmentation(im,TA,1,1,1,1,0);
    else
        [im,TA]=random_augmentation(im,TA,1,1,0,0,0);
    end

    if kpall==0
        maxn=ct(type);
        kp=ct<=maxn*1.05;
    else
        kp=ct>0;
    end
    %if type==4;kp(6)=1;end
    kp=[0 kp];
    tmp=kp(TA+1);

    dil=randi(15)+15;
    tmp=imdilate(tmp,strel('disk',dil));
    TA=TA.*double(tmp);
    im=im.*double(tmp);
    kpout=unique(TA);kpout=kpout(2:end);

    p1=min([sT size(TA,1)]);
    p2=min([sT size(TA,2)]);
    im=im(1:p1,1:p2,:);TA=TA(1:p1,1:p2);
    im=uint8(im);
    TA=uint8(TA);
end
