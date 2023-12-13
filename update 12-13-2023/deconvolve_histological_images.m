function deconvolve_histological_images(pth,stain_type)
% this function will deconvolve an H&E or IHC (stained using diaminobenzadine) 
% into hematoxylin and eosin / diaminobenzadine channels. 
% REQUIRED INPUT:
% pth: folder containing images to deconvolve
% stain_type: 1 for H&E, 2 for IHC. default is H&E
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

path(path,'cell_detection_base_functions');
warning ('off','all');

if pth(end)~='\';pth=[pth,'\'];end
outpthH=[pth,'Hchannel\'];mkdir(outpthH);
outpthE=[pth,'Echannel\'];mkdir(outpthE);


imlist=dir([pth,'*tif']);if isempty(imlist);imlist=dir([pth,'*jpg']);end

if ~exist('stain_type','var');stain_type=1;end
if stain_type==1 % H&E
    CVS=[0.644 0.717 0.267;0.093 0.954 0.283;0.636 0.001 0.771]; 
elseif stain_type==2 % IHC
    CVS=[0.65 0.70 0.29;0.27 0.57 0.78;0.71 0.42 0.56];
end

for k=1:length(imlist)
        imnm=imlist(k).name;
        disp(['deconvolving histological image ',num2str(k),' of ',num2str(length(imlist)),': ',imnm])
        if exist([outpthH,imnm],'file');disp('  already done');continue;end
        
        im0=imread([pth,imnm]);

        [~,imH,imE]=colordeconv_log10(im0,CVS);
        
        imwrite(uint8(imH),[outpthH,imnm]);
        imwrite(uint8(imE),[outpthE,imnm]);
        disp('  done')
end
warning ('off','all');


end

