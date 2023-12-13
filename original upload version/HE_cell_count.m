function HE_cell_count(pth)
path(path,'\\motherserverdw\ashleysync\PanIN Modelling Package\image registration');       % for getting DAB stain from IHC images


outpth=[pth,'cell_coords\'];
mkdir(outpth);

imlist=dir([pth,'*tif']);
if isempty(imlist);imlist=dir([pth,'*jp2']);end

tic;
xyc=zeros([1 length(imlist)]);
tot_area=zeros([1 length(imlist)]);
tic;
for kk=1:length(imlist)
    imnm=imlist(kk).name;
    if exist([outpth,imnm(1:end-3),'mat'],'file');continue;end
    %if kk>1 && contains(imnm(end-5),'0');disp(imnm);continue;end
    
        % count cells
        imH=imread([pth,imnm]);
        imH=imH(:,:,1);
        ii=imH;ii=ii(ii~=0);imH(imH==0)=mode(ii);
        imH=255-imH;

        %imB=bpassW(imH,1,3); % size of noise, size of object
        imB=imgaussfilt(imH,1);
        xy=pkfndW(double(imB),110,7); % minimum brightness, size of object
        %whos xy0 xy
        if kk==1;figure(2),imshow(255-imH);axis equal;hold on;plot(xy(:,1),xy(:,2),'ro');end
        disp(round([kk length(imlist) xyc(kk)]))
        
%         ii=sub2ind(size(imB),xy(:,2),xy(:,1));
%         ind=imH(ii);
%         ii=ii(ind>170);
%         [y,x]=ind2sub(size(imB),ii);
%         xy=[x y];
        
        %figure(2),imshow(255-imH);axis equal;hold on;plot(xy(:,1),xy(:,2),'ro');
        %figure,imshow(255-imH);axis equal;hold on;plot(xy(:,1),xy(:,2),'ro');
        %whos xy
        %xy{kk}=count_cells(imH);
        xyc(kk)=size(xy,1);
        
        
        %t=imB>3;
        %t=imclose(t,strel('disk',3));
        %t=bwareaopen(t,1000);
        %tot_area(kk)=sum(t(:))*2*2/1000000; % area in square mm
        
%     save([outpth,imnm(1:end-3),'mat'],'xy','tot_area');
    save([outpth,imnm(1:end-3),'mat'],'xy');
end
% save([pth,'cell_locations.mat'],'xy','xyc','tot_area','-v7.3');
% figure,plot([1:length(imlist)]*12/1000,xyc),title('cell count');
% xlabel('mm along z axis')
% ylabel('cell count per tissue section')
% ylim([0 2500000])

% figure,plot([1:length(imlist)]*12/1000,xyc./tot_area),title('density');
% xlabel('mm along z axis')
% ylabel('cell density per tissue section (cells / mm^2)')
% ylim([0 10000])
end



