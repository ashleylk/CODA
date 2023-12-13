function cell_detection(pth,pthparams)
% this function will calculate cellular coordinates for all images in pth
% given the optimization parameters saved in pthparams
% REQUIRED INPUTS:
% pth: pth containing color-deconvolved channel of histological images
% pthparams: subfolder containing the optimized 'mb' and 'sz' variables
% Written in 2019 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

path(path,'cell_detection_base_functions');       % for getting DAB stain from IHC images

if pth(end)~='\';pth=[pth,'\'];end
if pthparams(end)~='\';pthparams=[pthparams,'\'];end
outpth=[pth,'cell_coords\'];
if ~isfolder(outpth);mkdir(outpth);end

imlist=dir([pth,'*tif']);
if isempty(imlist);imlist=dir([pth,'*jpg']);end

% load optimized cell detection settings
load([pthparams,'optimized_params.mat'],'mb','sz');

tic;
for kk=1:length(imlist)
    imnm=imlist(kk).name;
    disp(['detecting cells in image ',num2str(kk),' of ',num2str(length(imlist)),': ',imnm])
    if exist([outpth,imnm(1:end-3),'mat'],'file');disp('  already calculated');continue;end
    
    % count cells
    imH=imread([pth,imnm]);
    imH=imH(:,:,1);
    ii=imH;ii=ii(ii~=0);imH(imH==0)=mode(ii);
    imH=255-imH;

    imB=imgaussfilt(imH,1);
    xy=pkfndW(double(imB),mb,sz); % minimum brightness, size of object
    %figure(2),imshow(255-imH);axis equal;hold on;plot(xy(:,1),xy(:,2),'ro');hold off;
    disp('  done')
        
      
    save([outpth,imnm(1:end-3),'mat'],'xy','mb','sz');
end

end



