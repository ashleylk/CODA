function save_images_elastic2(pthim,pthdata,scale,padnum,ext)
if ~exist('padnum','var');pd=1;else;pd=0;end
if ~exist('ext','var');ext=[];end
imlist=dir([pthim,'*tif']);fl='tif';
if isempty(imlist);imlist=dir([pthim,'*jp2']);fl='jp2';end
if isempty(imlist);imlist=dir([pthim,'*jpg']);fl='jpg';end

matlist=dir([pthdata,'D\','*mat']);
try 
    datafileE=[pthdata,matlist(1).name];
    load(datafileE,'szz','padall');
catch
    datafileE=[pthdata,matlist(end).name];
    load(datafileE,'szz','padall');
end
padall=ceil(padall*scale);
refsize=ceil(szz*scale);

% determine roi and create output folder
outpth=[pthim,'registeredE',ext,'\'];
if ~isfolder(outpth);mkdir(outpth);end

% register each image and save to outpth
for kz=1:length(matlist)
    imnm=[matlist(kz).name(1:end-3),fl];
    outnm=imnm;
    if exist([outpth,outnm],'file');disp(['skip image ',num2str(kz)]);continue;end
    %if contains(imnm,'CD');continue;end
    if ~exist([pthim,imnm],'file');continue;end
    datafileE=[pthdata,imnm(1:end-3),'mat'];
    datafileD=[[pthdata,'D\'],imnm(1:end-3),'mat'];
    if ~exist(datafileD,'file');continue;end
    f=0;
    
    % load image
    IM=imread([pthim,imnm]);
    szim=size(IM(:,:,1));
    if pd;padnum=squeeze(mode(mode(IM,2),1))';end
    if szim(1)>refsize(1) || szim(2)>refsize(2)
        a=min([szim; refsize]);
        IM=IM(1:a(1),1:a(2),:);
    end
    IM=pad_im_both2(IM,refsize,padall,padnum);
    
    
    % if not reference image, register
    try
        load(datafileE,'tform','cent','f');
        if f==1;IM=IM(end:-1:1,:,:);end
        IMG=register_IM(IM,tform,scale,cent,padnum);

        load(datafileD,'D');
        D2=imresize(D,size(IM(:,:,1)));
        D2=D2.*scale;
        IME=imwarp(IMG,D2,'nearest','FillValues',padnum);
    % no transformation if this is reference image
    catch
        IME=IM;
    end
    
    if kz==1
       pth1=[pthdata,'..\'];
       try 
           im=imread([pth1,matlist(kz).name(1:end-3),'jpg']);
       catch
           im=imread([pth1,matlist(kz).name(1:end-3),'tif']);
       end
       im2=imresize(IME,size(im(:,:,1)),'nearest');
       figure,imshowpair(im,im2);pause(2);
    end
    
    %rr=[11112 3083 27452 24046];
    %rr=[8280 4817 32014 22462];
    %rr=[9139 3097 37968 26544];
    %IME=imcrop(IME,rr);
    imwrite(IME,[outpth,outnm]);
    disp([kz length(imlist)]);%disp(imnm)
    clearvars tform rsc cent D
end

end

function IM=register_IM(IM,tform,scale,cent,abc)    
    % rough registration
    cent=cent*scale;
    tform.T(3,1:2)=tform.T(3,1:2)*scale;
    Rin=imref2d(size(IM));
        Rin.XWorldLimits = Rin.XWorldLimits-cent(1);
        Rin.YWorldLimits = Rin.YWorldLimits-cent(2);
    IM=imwarp(IM,Rin,tform,'nearest','outputview',Rin,'fillvalues',abc);
end