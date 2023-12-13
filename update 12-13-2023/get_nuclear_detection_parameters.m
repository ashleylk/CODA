function get_nuclear_detection_parameters(pthmosaic)
% using color deconvolved images and manual cell coordinates, this function
% will optimize parameters for automatic cell detection of H&E images
% REQUIRED INPUT:
% pthmosaic: folder containing the mosaic image. Inside a subfolder named 
% manual detectoin folder should be a tif image named 'mosaic.tif', a mat 
% file named 'mosaic.mat' containing a variable 'xym' with manually annotated 
% nuclear coordinates, % and a subfolder 'Hchannel' containing the color
% deconvolved hematoxylin channel image.
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% with input from Andre Forjaz, Lucie Dequiedt, and Vasco Quieroga
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if pthmosaic(end)~='\';pthmosaic=[pthmosaic,'\'];end

% deconvolve mosaic image
deconvolve_histological_images(pthmosaic);

% load mosaic image hematoxylin channel
pthmosaicH=([pthmosaic,'Hchannel\']);
pthmanual=([pthmosaic,'manual detection\']);
im0=imread([pthmosaic,'mosaic.tif']);   % rgb image
imH=imread([pthmosaicH,'mosaic.tif']); % H-channel image
imH=imH(:,:,1);
imH=255-imH;
imB=imgaussfilt(imH,1);

% load manual cell coordinates
load([pthmanual,'mosaic.mat'],'xym');

% first, optimize the brightness
sz=11; % choose a size to start with
mbs=50:2:200;
[mb]=calculate_optimal_vals(imB,mbs,sz,xym);

% second, optimize size
szs=3:21;
[~,sz]=calculate_optimal_vals(imB,mb,szs,xym);

% re-optimize brightness over a narrower range
mbs=mb-10:mb+10;
[mb,sz,xya,TP,FP,FN]=calculate_optimal_vals(imB,mbs,sz,xym);

% save output values
outpth=[pthmosaic,'automatic detection\'];
if ~isfolder(outpth);mkdir(outpth);end
save([outpth,'optimized_params.mat'],'mb','sz');
save([outpth,'mosaic.mat'],'xya','TP','FP','FN');
disp(' optimal cell detection paramaters generated.')
disp(['  True positives: ',num2str(round(TP*100)),'%']);
disp(['  False positives: ',num2str(round(FP*100)),'%']);
disp(['  False negatives: ',num2str(round(FN*100)),'%']);
figure;imshow(im0);hold on;
    scatter(xym(:,1),xym(:,2),'oc');
    scatter(xya(:,1),xya(:,2),'*y');
    legend({'manual coords','automatic coords'})


