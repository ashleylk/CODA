function save_images_global(pthim,pthdata,scale,padnum,tpout)
if ~exist('padnum','var');pd=1;else;pd=0;end
if ~exist('tpout','var');tpout='tif';end

imlist1=dir([pthim,'*tif']);
imlist2=dir([pthim,'*jpg']);
imlist3=dir([pthim,'*jp2']);
imlist=[imlist1;imlist2;imlist3];

try 
    datafile=[pthdata,imlist(1).name(1:end-3),'mat'];
    load(datafile,'szz','padall');
catch
    datafile=[pthdata,imlist(2).name(1:end-3),'mat'];
	load(datafile,'szz','padall');
end
padall=ceil(padall*scale);
refsize=ceil(szz*scale);

% determine roi and create output folder
outpth=[pthim,'registeredG\'];
if ~isfolder(outpth);mkdir(outpth);end

% register each image and save to outpth
for kz=1:length(imlist)
    imnm=imlist(kz).name;
    outnm=[imlist(kz).name(1:end-3),tpout];
    
    %if exist([outpth,outnm],'file');continue;end
    disp([kz length(imlist)]);disp(imnm)
    datafile=[pthdata,imnm(1:end-3),'mat'];
    
    % load image
    IM=imread([pthim,imnm]);
    szim=size(IM(:,:,1));
    if pd;padnum=squeeze(mode(mode(IM,2),1))';end
    if szim(1)>refsize(1) || szim(2)>refsize(2)
        a=min([szim; refsize]);
        IM=IM(1:a(1),1:a(2),:);
    end
    IM=pad_im_both(IM,refsize,padall,padnum);
    
    try 
        % if not reference image, register
        load(datafile,'tform','cent','f');
        if ~exist('f','var');f=0;end
        if f==1;IM=IM(end:-1:1,:,:);end
        IMG=register_IM(IM,tform,scale,cent,padnum);
        imwrite(IMG,[outpth,outnm]);
        clearvars tform
    catch
        % no transformation if this is reference image
        imwrite(IM,[outpth,outnm]);
    end
    
    clearvars f
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