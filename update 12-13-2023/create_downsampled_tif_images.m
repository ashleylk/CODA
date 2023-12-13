function create_downsampled_tif_images(pth,ds,subfolders)
% this function will create downsampled tif images from high resolution files
% requires a lot of RAM. as an alternative, try openslide
% INPUTS: 
% pth: a folder containing .npdi or .svs images
% ds: a matrix containing desired pixel resolutions you want to create
%     example: ds=[1 2 10] (create downsampled imaegs with resolutions of 1, 2, and 10 micron/pixel
% subfolders: a string array containing the output folder names to save the tifs in
%     example: subfolders=["10x" "5x" "1x"]; (save images in subfolders with these names)
%     note: assumes 10x=~1um/pixel, 5x=~2um/pixel, 1x=~10um/pixel
% OUTPUTS:
% 1. tif images will be created at all downsample factors in ds
%    and will be saved in folders subfolders created within pth
warning ('off','all');
disp('creating downsampled tif images')


if pth(end)~='\';pth=[pth,'\'];end
imlist=dir([pth,'*.ndpi']);ft='ndpi';
if isempty(imlist);imlist=dir([pth,'*.svs']);ft='svs';end
if isempty(imlist);imlist=dir([pth,'*.scn']);ft='scn';end

% set image output folder
if length(ds)>1
    outpth=[pth,char(subfolders(1))];
    outpthe=[pth,char(subfolders(end))];
else
    outpth=[pth,subfolders];
    outpthe=outpth;
end
if outpth(end)~='\';outpth=[outpth,'\'];end
if ~isfolder(outpth);mkdir(outpth); end

% output image type
tps='tif';

ds0=ds(1);
for k=1:length(imlist)
    nm=imlist(k).name;tic;
    mpp=get_mpp_of_image(pth,nm);
    disp(['downsampling image ',num2str(k),' of ',num2str(length(imlist)),': ',nm])
    nmout=strrep(nm,ft,tps);
    
    if exist([outpth,nmout],'file') && exist([outpthe,nmout],'file')
        disp('   PREVIOUSLY LOADED');
        continue;
    end
    
    % get size of image
    tmp=imfinfo([pth,nm]);
    image_layer=cat(1,tmp.Height);
    image_layer=find(image_layer==max(image_layer));
    fx=ds0/mpp; % resizing factor to produce image of 2um/pixel

    imtif=imread([pth,nm],image_layer);
    xx=ceil(size(imtif(:,:,1))/fx);
    imtif=imresize(imtif,xx,'nearest');
    
    imwrite(imtif,[outpth,nmout]);
    for jj=2:length(ds)
        outpth2=[pth,char(subfolders(jj))];
        if outpth2(end)~='\';outpth2=[outpth2,'\'];end
        if ~isfolder(outpth2);mkdir(outpth2);end
        
        % calculate rescale factor: ex. 2um/px --> 8um/px = rescale image to 1/4
        xx=ds(1)/ds(jj); 
        imtif2=imresize(imtif,xx,'nearest');
        imwrite(imtif2,[outpth2,nmout]);
    end
    disp(['  Finished in ',num2str(round(toc)),' seconds.'])
    
end

