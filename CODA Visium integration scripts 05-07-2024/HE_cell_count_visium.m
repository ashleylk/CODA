function HE_cell_count_visium(pth)
path(path,'\\motherserverdw\ashleysync\PanIN Modelling Package\image registration');       % for getting DAB stain from IHC images
outpth=[pth,'cell_coords\'];
mkdir(outpth);
imlist=dir([pth,'*tif']);

tic;
for kk=1:length(imlist)
    imnm=imlist(kk).name;
    if exist([outpth,imnm(1:end-3),'mat'],'file');continue;end
    
        % count cells
        imH=imread([pth,imnm]);
        imH=double(imH);
        tmp=imH(:,:,3)-imH(:,:,1);
        tmp=imgaussfilt(tmp,1);
        xy=pkfndW(double(tmp),70,7); % minimum brightness, size of object
        % figure(2),imshow(uint8(imH));axis equal;hold on;plot(xy(:,1),xy(:,2),'ro');

        disp(round([kk length(imlist)]))
        save([outpth,imnm(1:end-3),'mat'],'xy');

        imout=zeros(size(tmp));
        ii=sub2ind(size(imout),xy(:,2),xy(:,1));
        imout(ii)=1;
        imwrite(uint8(imout),[outpth,imnm]);
end

end



