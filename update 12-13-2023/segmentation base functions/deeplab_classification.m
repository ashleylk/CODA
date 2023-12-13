function deeplab_classification(pth5x,pthDL,sxy,nm,cmap,nblack,nwhite,col)
% this function will classify RGB images using the trained deeplab model
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if ~exist('col','var');col=0;end

load([pthDL,'net.mat'],'net');
outpth=[pth5x,'classification_',nm,'\'];
mkdir(outpth);

b=100;
imlist=dir([pth5x,'*tif']);
if isempty(imlist);imlist=dir([pth5x,'*jp2']);end
if isempty(imlist);imlist=dir([pth5x,'*jpg']);end

x=tic;

for kk=1:length(imlist)
    tic;
    disp(['segmenting image ',num2str(kk),' of ',num2str(length(imlist)),': ',imlist(kk).name])
    if exist([outpth,imlist(kk).name(1:end-3),'tif'],'file');disp('  already segmented');continue;end
    
    im=imread([pth5x,imlist(kk).name]);
    try
        TA=imread([pth5x,'TA\',imlist(kk).name(1:end-3),'tif']);
    catch
        TA=rgb2gray(im)<220;
        imfill(TA,'holes');
    end
    
    % pad image so we classify all the way to the edge
    im=padarray(im,[sxy+b sxy+b],0,'both');
    TA=padarray(TA,[sxy+b sxy+b],1,'both');
    
    imclassify=zeros(size(TA));
    sz=size(im);
    for s1=1:sxy-b*2:sz(1)-sxy
        for s2=1:sxy-b*2:sz(2)-sxy
            tileHE=im(s1:s1+sxy-1,s2:s2+sxy-1,:);
            tileTA=TA(s1:s1+sxy-1,s2:s2+sxy-1,:);
            if sum(tileTA(:))<100
                tileclassify=zeros(size(tileTA));
            else
                tileclassify=semanticseg(tileHE,net);
            end
            tileclassify=tileclassify(b+1:end-b,b+1:end-b,:);
            imclassify(s1+b:s1+sxy-b-1,s2+b:s2+sxy-b-1)=tileclassify;

%             tileclassify=double(tileclassify);
%             tileclassify(tileclassify==nblack | tileclassify==0)=nwhite;
%             imcolor=uint8(cat(3,am(tileclassify),bm(tileclassify),cm(tileclassify)));
%             tileHE=tileHE(b+1:end-b,b+1:end-b,:);
%             figure(18),
%                 subplot(1,2,1),imshow(tileHE)
%                 subplot(1,2,2),imshow(imcolor)
        end
    end
   
    % remove padding
    im=im(sxy+b+1:end-sxy-b,sxy+b+1:end-sxy-b,:);
    imclassify=imclassify(sxy+b+1:end-sxy-b,sxy+b+1:end-sxy-b,:);
    
    disp(['  finished in ',num2str(round(toc)),' seconds'])
    imclassify(imclassify==nblack | imclassify==0)=nwhite; % make black class and zeros class whitespace
    imwrite(uint8(imclassify),[outpth,imlist(kk).name(1:end-3),'tif']);
    
    if col==1
        outpthcolor=[outpth,'color\'];
        if ~isfolder(outpthcolor);mkdir(outpthcolor);end
        am=cmap(:,1);bm=cmap(:,2);cm=cmap(:,3);
        imcolor=uint8(cat(3,am(imclassify),bm(imclassify),cm(imclassify)));
        imwrite(imcolor,[outpthcolor,imlist(kk).name(1:end-3),'tif']);
    end

    if kk==3 && ~isempty(cmap)
        am=cmap(:,1);bm=cmap(:,2);cm=cmap(:,3);
        try
            imcolor=uint8(cat(3,am(imclassify),bm(imclassify),cm(imclassify)));
        catch
            disp('fds')
        end
        figure;subplot(1,2,1);imshow(im);subplot(1,2,2);imshow(imcolor)
        ha=get(gcf,'children');linkaxes(ha);
    end

    if rem(kk,1)==0%col==2 
        outpth2=[outpth,'check_classification\'];
        if ~isfolder(outpth2);mkdir(outpth2);end
        make_check_annotation_classified_image(im,imclassify,cmap,2,[outpth2,imlist(kk).name(1:end-3),'tif']);
    end
end
disp(['total time: ',num2str(round(toc(x)/60)),' minutes'])