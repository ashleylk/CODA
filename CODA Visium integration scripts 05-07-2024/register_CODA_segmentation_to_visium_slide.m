function register_CODA_segmentation_to_visium_slide(im,imC,imCcolor,imcell,filenamecsv,ff,nn,titles)
% this function will register the high-resolution H&E image scan to the
% Visium scan of the H&E image. It will then determine the number of
% nuclear coordinates and estimate the cell type of each cell within each
% Visium spot.
% function inputs:
% im          = 8-bit visium high resolution H&E image
% imC         = 8-bit CODA classified image
% imCcolor    = 8-bit colorized CODA classified image
% imcell      = 8-bit image mask containing cell coordinates
% filenamecsv = character array of location and filename of csv file containing coordinates of the centroids of each visium spot
%               example: filenamecsv='C:\Users\Ashley\Documents\tissue_positions_list.csv';
% ff          = segmentation model class ID of the fiducial points
%               example: ff=8;
% nn          = scale factor between exported Visium scan H&E and
%               classified H&E image
% titles      = cell containing the name of each class in the segmentationmodel in order 
%               example: titles={'vasculature','fat','stroma'};
% function output: this script will save an updated csv file in the same
%                  location where filenamecsv is saved, containing columns
%                  with the number of each cell type within each Visium spot

if ~exist('nn','var');nn=1;end

[~,~,data]=xlsread(filenamecsv);
imF=imC==ff;
imF=bwareaopen(imF,500); % fiducial markers

% load visium H&E image
im=im(:,:,1:3);
imV1=mean(im,3)<225;
imV=imclose(imV1,strel('disk',2));
imV=imfill(imV,'holes');
imV=bwareaopen(imV,100);
imV=imV-bwareaopen(imV,200);
figure,imshow(imV)

% load classified images
if ~exist('imF','var')
    imF0=get_fiducials(imCcolor);
    imF=bwareaopen(imF0==1,500);
    imF=imF-bwareaopen(imF,8000);
end

% find translation and scale between images
[rrV,rrC,scale,ang]=try_four_rotations(imV,imF);

% scale images
imC=imrotate(imC,ang);
imCcolor=imrotate(imCcolor,ang);
imcell=imrotate(imcell,ang);
imscale=imtranslate(im,[-rrV(1) -rrV(2)]);
imscale=imresize(imscale,scale);
imscale=imtranslate(imscale,[rrC(1) rrC(2)]);

szz=min([size(imC);size(imscale(:,:,1))]);
imC=imC(1:szz(1),1:szz(2),:);
imCcolor=imCcolor(1:szz(1),1:szz(2),:);
imcell=imcell(1:szz(1),1:szz(2),:);
imscale=imscale(1:szz(1),1:szz(2),:);
figure(31),imshowpair(imscale,imCcolor);

% load visium coordinates
x=cell2mat(data(:,5));
y=cell2mat(data(:,6));
x=x*nn;y=y*nn;
xs=round((x-rrV(2))*scale+rrC(2));
ys=round((y-rrV(1))*scale+rrC(1));
figure(32),
    subplot(1,2,1);imshow(imscale);hold on;scatter(ys,xs,5,'g','filled');
    subplot(1,2,2);imshow(imCcolor);hold on;scatter(ys,xs,5,'g','filled');

% get grid of 50micron diameter circles at points of interest
figure,imshow(im);hold on;scatter(y,x,5,'g','filled');title('unregistered')
rad=25+4; % convert rom um to pixels

% zero-pad titles
titles2=cell([1 length(titles)+6]);
titles2(7:end)=titles;
titles=titles2;
% export cell and tissue info
number_of_cells(xs,ys,rad,imcell,data,titles,filenamecsv,imCcolor);
tissue_composition(xs,ys,rad,imC,data,titles,filenamecsv);
end

function number_of_cells(xs,ys,rad,imcell,data,titles,outfile,imCcolor)
    szz=size(imCcolor(:,:,1));
    dim=linspace(-1,1,rad*2+1);
    [X,Y] = ndgrid(dim,dim);
    R = sqrt(X.^2 + Y.^2);
    circ = zeros(size(X));
    circ(R<=1)=1;
    ii=sub2ind(szz,xs,ys);
    out=zeros([length(xs) length(titles)-6]);

    imd=zeros(szz);imdC=imd;
    hascellsx=[];hascellsy=[];
    for b=1:length(ii)
        r1=xs(b)-rad:xs(b)+rad;
        r2=ys(b)-rad:ys(b)+rad;
        imd(r1,r2)=circ*b;
        tmpc=imcell(r1,r2).*circ;%tmp=imC(r1,r2).*circ;
        imdC(r1,r2)=tmpc;
    
        % get composition of tissue within each fiducial
        tmp=histcounts(tmpc(:),0:size(out,2)+1);
        tmp=tmp(2:end);
        tmp(6)=tmp(6)+tmp(4);
        tmp(4)=0;tmp(7)=0;
        out(b,:)=tmp;
        if sum(tmp>0)
            hascellsx=cat(1,hascellsx,xs(b));
            hascellsy=cat(1,hascellsy,ys(b));
        end
    end
    figure;imshow(imCcolor);hold on;scatter(hascellsy,hascellsx,15,'og','filled')
    outcell=num2cell(out);
    
    outdata=cat(2,data,outcell);
    outdata=cat(1,titles,outdata);
    writecell(outdata,strrep(outfile,'.csv','_cellular_count.csv'));

    out=out./(sum(out,2))*100;
    out(isnan(out))=0;
    outcell=num2cell(out);
    outdata=cat(2,data,outcell);
    outdata=cat(1,titles,outdata);
    writecell(outdata,strrep(outfile,'.csv','_cellular_compositions.csv'));
end

function tissue_composition(xs,ys,rad,imC,data,titles,outfile)
    szz=size(imC);
    dim=linspace(-1,1,rad*2+1);
    [X,Y] = ndgrid(dim,dim);
    R = sqrt(X.^2 + Y.^2);
    circ = zeros(size(X));
    circ(R<=1)=1;
    ii=sub2ind(szz,xs,ys);
    out=zeros([length(xs) length(titles)-6]);

    imd=zeros(szz);imdC=imd;
    for b=1:length(ii)
        r1=xs(b)-rad:xs(b)+rad;
        r2=ys(b)-rad:ys(b)+rad;
        imd(r1,r2)=circ*b;
        tmp=imC(r1,r2).*circ;
        imdC(r1,r2)=tmp;
        
        % get composition of tissue within each fiducial
        tmp=histcounts(tmp(:),0:size(out,2)+1);
        out(b,:)=tmp(2:end);
    end
    out=out./sum(out,2)*100;
    outcell=num2cell(out);
    
    outdata=cat(2,data,outcell);
    outdata=cat(1,titles,outdata);
    
    writecell(outdata,strrep(outfile,'.csv','_tissue_compositions.csv'));
end


function [rrV,rrC,scale,ang]=try_four_rotations(imV,imF0)
    [rrV,distV]=get_corner_pts(imV);

    corr=[0 0 0 0];
    count=1;
    rrCs=zeros(4);
    scales=[0 0 0 0];
    angs=[0 90 180 270];
    for kk=[0 90 180 270]
        imF=imrotate(imF0,kk);
        [rrCs(count,:),distC]=get_corner_pts(imF);
        scales(count)=distC/distV;
        
        imscale=imtranslate(imV,[-rrV(1) -rrV(2)]);
        imscale=imresize(imscale,scales(count));
        imscale=imtranslate(imscale,[rrCs(count,1) rrCs(count,2)]);
        b=min([size(imF);size(imscale)]);
        imF=imF(1:b(1),1:b(2));
        imscale=imscale(1:b(1),1:b(2));
        corr(count)=corr2(imF,imscale);
        count=count+1;
    end
    [~,i]=max(corr);
    scale=scales(i);
    ang=angs(i);
    rrC=rrCs(i,:);
    disp(corr);disp(i)
end

function imout=get_fiducials(im)
    cmap=[121 248 252;...   % 1 islet
          000 000 255;...   % 2 duct
          080 237 080;...   % 3 blood vessel
          255 255 000;...   % 4 fat
          149 035 184;...   % 5 acinus
          255 194 245;...   % 6 connective tissue
          255 000 000];...  % 8 PanIN
    ima=im(:,:,1);
    imb=im(:,:,2);
    imc=im(:,:,3);
    imout=zeros(size(ima));
    for b=1:size(cmap,1)
        tmp1=ima==cmap(b,1);
        tmp2=imb==cmap(b,2);
        tmp3=imc==cmap(b,3);
        tmp=tmp1 & tmp2 & tmp3;
        imout(tmp)=0.5;
        ima(tmp==1)=255;
    end
    imout(ima~=255)=1;

end

function [rr,dist]=get_corner_pts(im0)
    c0=regionprops(im0>0,'Centroid');
    c0=round(cat(1,c0.Centroid));

    % crop im
    b1=sum(im0,1);b2=sum(im0,2);
    bb=[find(b1>0,1,'first') find(b1>0,1,'last') find(b2>0,1,'first') find(b2>0,1,'last')];
    im=im0(bb(3):bb(4),bb(1):bb(2),:);
    c=regionprops(im>0,'Centroid');
    c=round(cat(1,c.Centroid));

    distTL=round(sqrt((c(:,1)-1).^2 + (c(:,2)-1).^2));
    tmp=find(distTL==min(distTL),1,'first');c1a=c0(tmp,:);d1a=distTL(tmp);
    distTL(distTL==min(distTL),:)=max(distTL);
    tmp=find(distTL==min(distTL),1,'first');c1b=c0(tmp,:);d1b=distTL(tmp);
    d1=abs(d1a-d1b)/d1b;
    if d1<0.5
        c1=round(mean([c1a;c1b]));
    else
        c1=c1a;
    end

    distBR=round(sqrt((c(:,1)-size(im,2)).^2 + (c(:,2)-size(im,1)).^2));
    tmp=find(distBR==min(distBR),1,'first');c2a=c0(tmp,:);d2a=distBR(tmp);
    distBR(distBR==min(distBR),:)=max(distBR);
    tmp=find(distBR==min(distBR),1,'first');c2b=c0(tmp,:);d2b=distBR(tmp);
    d2=abs(d2a-d2b)/d2b;
    if d2<0.5
        c2=round(mean([c2a;c2b]));
    else
        c2=c2a;
    end

    rr=[c1 c2];
    dist=round(sqrt((rr(1)-rr(3)).^2 + (rr(2)-rr(4)).^2));

    %figure,imshow(im0);hold on;scatter(c1(1),c1(2),'*g');scatter(c2(1),c2(2),'*g');
end


% rescale visium to classified size
% h=figure;imshow(im);title('draw line connecting to features');
% roiV=drawline;
% rrV=[roiV.Position(1,1) roiV.Position(2,1) roiV.Position(1,2) roiV.Position(2,2)];
% distV=round(sqrt((rrV(1)-rrV(2)).^2 + (rrV(3)-rrV(4)).^2));
% close(h);

% h2=figure;imshow(imF);title('draw line connecting same features');
% roiC=drawline;
% rrC=[roiC.Position(1,1) roiC.Position(2,1) roiC.Position(1,2) roiC.Position(2,2)];
% distC=round(sqrt((rrC(1)-rrC(2)).^2 + (rrC(3)-rrC(4)).^2));
% close(h2);
% scale=distC/distV;
% imscale=imresize(im,scale);
% figure,imshowpair(imscale,imF)