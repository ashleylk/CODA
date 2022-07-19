function normalize_HE(pth,pthl,outpth)
warning ('off','all');
path(path,'\\motherserverdw\ashleysync\PanIN Modelling Package\'); 
path(path,'\\motherserverdw\ashleysync\PanIN Modelling Package\IHC segmentation\'); 
% add in histogram equalization to make outputs better match

if ~exist('pthl','var');pthl=pth;end
if ~exist('outpth','var');outpth=[pth,'fix stain\'];end
outpthC=[outpth,'CVS\'];
outpthH=[outpth,'Hchannel\'];
mkdir(outpth);mkdir(outpthC);mkdir(outpthH);%mkdir(outpthE);


tic;
imlist=dir([pth,'*tif']);if isempty(imlist);imlist=dir([pth,'*jpg']);end
knum=150000;
CVS=[0.644 0.717 0.267;0.093 0.954 0.283;0.636 0.001 0.771];

% CVS=[0.578 0.738 0.348;...
%     0.410 0.851 0.328;...
%     0.588 0.625 0.514];
% CVS=[0.5157    0.7722    0.3712
%     0.3519    0.8409    0.4112
%     0.5662    0.1935    0.6088];
for kk=1:length(imlist)
        imnm=imlist(kk).name;
        if exist([outpthH,imnm],'file');disp(['skip ',num2str(kk)]);continue;end
        disp([num2str(kk), ' ', num2str(length(imlist)), ' ', imnm(1:end-4)]);
        
        im0=imread([pth,imnm]);
%         [CVS,TA]=make_rgb_kmeans_90(im0,knum,0);
        %CVS=[0.759 0.587 0.280;0.673 0.630 0.387;0.763 0.001 0.646]; % im1
        %save([outpthC,imnm(1:end-3),'mat'],'CVS');
        
        [imout,imH,imE]=colordeconv2pw4_log10(im0,"he",CVS);
        %load([outpthC,imlist(1).name(1:end-3),'mat'],'CVS');ODout=CVS;
        
        %figure(3),imshow(imH)
        imwrite(uint8(imH),[outpthH,imnm]);
        disp([kk length(imlist)])
end
warning ('off','all');
end

