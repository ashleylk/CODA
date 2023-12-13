function build_cell_volume(pthclassifiedE,pthcoordsE,pthvolume,scale,nwhite)
% creates a volumetric matrix 'volcell' the same size as vol that contains nuclear coordinates
% REQUIRED INPUTS:
% pthclassifiedE: the folder containing the registered, classified images
% pthcoordsE: the folder containing the registered cell coordinates
% pthvolume: the folder containing the tissue matrix 'vol'
% scale: the scale between classified images and images used for cell detection, this is probably 1
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if pthclassifiedE(end)~='\';pthclassifiedE=[pthclassifiedE,'\'];end
if pthcoordsE(end)~='\';pthcoordsE=[pthcoordsE,'\'];end
if pthvolume(end)~='\';pthvolume=[pthvolume,'\'];end

% get crop and subsampling information from tissue matrix
load([pthvolume,'volume.mat'],'rr','sk');
warning ('off','all');

if exist([pthvolume,'volcell.mat'],'file')
    disp(' VOLCELL ALREADY MADE');
else
    list=dir([pthcoordsE,'*.mat']);

    % get size of volcell
    nm=list(1).name;
    nmim=strrep(nm,'.mat','.tif');
    a=imfinfo([pthclassifiedE,strrep(nm,'mat','tif')]);
    a=[a.Height a.Width];
    im00=imread([pthclassifiedE,nmim],'PixelRegion',{[1 sk a(1)],[1 sk a(2)]});
    im00=zeros(size(im00));
    im0=imcrop(im00,rr);
   
    volcell=uint8(zeros([size(im0) length(list)]));
    for k=1:length(list)
        nm=list(k).name;
        load([pthcoordsE,nm],'xye');
        xye=round(xye/scale/sk);
        x=xye(:,1);y=xye(:,2);
        kp=x>0 & y>0 & x<=size(im00,1) & y<size(im00,2);
        x=x(kp);y=y(kp);
        ii=sub2ind(size(im00),y,x);
        imvolcell=im00;
        for n=1:length(ii);imvolcell(ii(n))=imvolcell(ii(n))+1;end
        imvolcell=imcrop(imvolcell,rr);
        
        volcell(:,:,k)=imvolcell;
        clearvars xye
    end

    save([pthvolume,'volcell.mat'],'volcell');
    load([pthvolume,'volume.mat'],'vol');
    whos vol volcell
    
    mm=ceil(length(list)/2);
    tmp=imadjust(imgaussfilt(double(volcell(:,:,mm)),2));
    figure;imshowpair(vol(:,:,mm),tmp)

    a=sum(double(volcell),3);a=a/max(a(:));a=imadjust(imgaussfilt(a,2));
    b=sum(vol~=nwhite,3);b=b/max(b(:));
    figure;imshowpair(a,b)
end
    
w = warning ('on','all');