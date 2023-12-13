function save_cell_coordinates_registered(pthim,pthcoords,scale)

% location of images and registration data
pthimG=[pth1x,'registered\'];
pthimE=[pth1x,'registered\elastic registration\'];
pthdata=[pth1x,'registered\elastic registration\save_warps\'];
matlist=dir([pthimE,'*jpg']);

padnum=0;
imlist=dir([pthim,'*tif']);
matlist=dir([pthdata,'D\','*mat']);
datafileE=[pthdata,matlist(1).name];
load(datafileE,'szz','padall');
padall=ceil(padall*scale);
refsize=ceil(szz*scale);
% pthim='G:\Alicia Braxton\TC_90 PDAC\1x\';
% determine roi and create output folder
outpth=[pthimE,'cell_coord_',nn,'_imagesE\'];
outpth2=[outpth,'mat_files\'];
mkdir(outpth);mkdir(outpth2);

volcell=[];
count=1;
% register each image and save to outpth
for kz=1:length(matlist)
    % check if registered image and cell coordinates exist
    try 
        load([pthcoords,matlist(kz).name],'xy');
        xy=round(xy/scalecoord);
        szim=imfinfo([pthim,matlist(kz).name(1:end-3),'tif']); % original 1x size
        szim=round([szim.Height szim.Width]*scale);
    catch
        continue;
    end
    
    % set up variables
    datafileE=[pthdata,matlist(kz).name];
    datafileD=[[pthdata,'D\'],matlist(kz).name];
    f=0;
    
    % create image
    %IM=imread([pthim,matlist(kz).name(1:end-3),'tif']);
    ii=sub2ind(szim,xy(:,2),xy(:,1));
    [a,e]=histcounts(ii,1:max(ii)-1);
    imxy=zeros(szim);
    imxy(e(1:end-1))=a;

    if szim(1)>refsize(1) || szim(2)>refsize(2)
        a=min([szim; refsize]);
        imxy=imxy(1:a(1),1:a(2),:);
    end
    imxy=pad_im_both(imxy,refsize,padall,padnum);
    
    % if not reference image, register
    try
        load(datafileE,'tform','cent','f');
        if f==1;imxy=imxy(end:-1:1,:,:);end
        IMG=register_IM(imxy,tform,scale,cent,padnum);
        load(datafileD,'D');
        D2=imresize(D,size(imxy(:,:,1)));
        D2=D2.*scale;
        imxyE=imwarp(IMG,D2,'nearest','FillValues',padnum);
    % no transformation if this is reference image
    catch
        disp('catch')
        imxyE=imxy;
    end
    
    % remake xy list
    y=[];x=[];
    for k=1:max(imxy(:))
        [yt,xt]=find(imxy>=k);
        y=cat(1,y,yt);x=cat(1,x,xt);
    end
    xye=[x y];
    
    %IME=imread([pthimE,matlist(kz).name(1:end-3),'jpg']);
    disp([kz length(matlist)]);%disp(imnm)
    disp([size(xy,1) size(xye,1)])
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




%     pth1x='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_059\1x\';
%     pthcoords='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_059\5x\cell_coords\';
%     scale=4;
%     datapth='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_059\1x\registered\elastic registration\save_warps\';
%     pthimG='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_059\1x\registered\';
%     pthimE='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_059\1x\registered\elastic registration\';
%     scim=2/3;
    
%     pth1x='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_001\1x\';
%     pthcoords='\\babyserverdw3\Digital Pathology\Panin1\Annotation\TC_001 Annotated\5x\kmeans_color_corrected\Hchannel\cell_coords\';
%     scale=4;
%     datapth='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_001\1x\registered\elastic registration\save_warps\';
%     pthimG='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_001\1x\registered\\';
%     pthimE='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_001\1x\registered\elastic registration\';
    
%     pth1x='\\babyserverdw4\Digital pathology image lib\Pancreas\PDAC\Seung-Mo Clearance Project\H&Es\1x\';
%     pthcoords='\\babyserverdw4\Digital pathology image lib\Pancreas\PDAC\Seung-Mo Clearance Project\H&Es\10x\cell_coords\';
%     scale=8;
%     datapth='\\babyserverdw4\Digital pathology image lib\Pancreas\PDAC\Seung-Mo Clearance Project\H&Es\1x\registered\elastic registration\save_warps\';
%     pthimG='\\babyserverdw4\Digital pathology image lib\Pancreas\PDAC\Seung-Mo Clearance Project\H&Es\1x\registered\';
%     pthimE='\\babyserverdw4\Digital pathology image lib\Pancreas\PDAC\Seung-Mo Clearance Project\H&Es\1x\registered\elastic registration\';
%     scim=4/3;
    
%     pth1x='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_082 IPMN Annotated\1x\';
%     pthcoords='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_082 IPMN Annotated\5x\color corrected self2\Hchannel\cell_coords\';
%     scale=4;
%     datapth='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_082 IPMN Annotated\1x\registered\elastic registration\save_warps\';
%     pthimG='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_082 IPMN Annotated\1x\registered\';
%     pthimE='\\babyserverdw4\Digital pathology image lib\Pancreas\PanIN\TC_082 IPMN Annotated\1x\registered\elastic registration\';
%     scim=2/3;