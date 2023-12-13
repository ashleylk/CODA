function calculate_image_registration(pth,IHC,zc,regE)
% Nonlinear registration of a series of 2D tumor sections cut along the z axis. Images will be warped into near-alignment.
% REQUIRED INPUT:
% pth: path to folder containing tif or jpg images to register. 
% OPTIONAL INPUTS:
% IHC: logical input. 1 if imagestack contains IHC images, 0 if stack contains only H&E images. 0 is default
% E: logical input. 1 if elastic registration is desired. 0 if only global registration. 1 is default
% zc: number of reference image for registration. default is the center of the list
% tpout: filetype for output registered images [example: 'tif']. default is 'jpg'
% regE: tilesize and spacing settings for elastic registration. default values below:
% OUTPUT:
% 1. A folder 'registered' inside pth containing the globally registered images in jpg format
% 2. A folder 'elastic registration inside 'registered' containing the elastically registered images in jpg format
% 3. A folder 'save_warps' inside 'elastic registration' containing the global registration matrices
% 4. A folder 'D' inside 'save_warps' containing the elastic registration transforms
% NOTE: if your results are bad and you wish to tune parameters (such as regE) and try again, first, delete the 'registered' folder inside the pth folder
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

% NOTE on elastic registration settings:
% if elastically registered images are too jiggly, try reducing szE and/or diE
% if elastically registered images are too smeared, try increasing szE and/or diE
% if registration is taking too long for one image (>5 min), try reducing the resolution of the images and/or try a computer with higher RAM
if ~exist('regE','var')
    regE.szE=251; % size of registration tiles 
    regE.bfE=200; % size of buffer on registration tiles
    regE.diE=100; % distance between tiles     
end

% add base functions to the MATLAB search path
path(path,'image registration base functions'); 

% default settings
warning ('off','all');
if ~exist('IHC','var') || isempty(IHC);IHC=0;end
if pth(end)~='\';pth=[pth,'\'];end

% output image type (can be 'jpg' or 'tif')
tpout='jpg';

% get list of images
imlist=dir([pth,'*tif']);
if isempty(imlist);imlist=dir([pth,'*jpg']);end
if isempty(imlist);disp('no images found');return;end
tp=imlist(1).name(end-2:end);

% calculate center image and order
if ~exist('zc','var') || isempty(zc);zc=ceil(length(imlist)/2);end
rf=[zc:-1:2 zc:length(imlist)-1 0];
mv=[zc-1:-1:1 zc+1:length(imlist)];

% find max size of images in list
szz=[0 0];
for kk=1:length(imlist)
    inf=imfinfo([pth,imlist(kk).name]);
    szz=[max([szz(1),inf.Height]) max([szz(2),inf.Width])]; 
end

% global registration settings
padall=250; % padding around all images
if IHC==1;rsc=2;else;rsc=6;end
iternum=5; % max iterations of registration calculation

% define outputs
outpthG=[pth,'registered\'];
outpthE=[outpthG,'elastic registration\'];
outpthE2=[outpthE,'check\'];mkdir(outpthE2);
matpth=[outpthE,'save_warps\'];
mkdir(outpthG);mkdir(matpth);
mkdir(outpthE);mkdir([matpth,'D\']);

% set up center image
nm=imlist(zc).name(1:end-3);
[imzc,TAzc]=get_ims(pth,nm,tp,IHC);
[imzc,imzcg,TAzc]=preprocessing(imzc,TAzc,szz,padall,IHC);
disp(['Reference image: ',nm])

% save reference image outputs
imwrite(imzc,[outpthG,nm,tpout]);
imwrite(imzc,[outpthE,nm,tpout]);
save([matpth,nm,'mat'],'zc');

img=imzcg;TA=TAzc;
img0=imzcg;TA0=TAzc;krf0=zc;
img00=imzcg;TA00=TAzc;krf00=zc;

for kk=1:length(mv)
    t1=tic;
    fprintf(['Image ',num2str(kk),' of ',num2str(length(imlist)-1),...
        '\n  reference image:  ',imlist(rf(kk)).name(1:end-4),...
        '\n  moving image:  ',imlist(mv(kk)).name(1:end-4),'\n']);
    % create moving image
    nm=imlist(mv(kk)).name(1:end-3);
    [immv0,TAmv]=get_ims(pth,nm,tp,IHC);
    [immv,immvg,TAmv,fillval]=preprocessing(immv0,TAmv,szz,padall,IHC);
    
    % reset reference images when at center
    if rf(kk)==zc
        imrfgA=img;TArfA=TA;krfA=zc;
        imrfgB=img0;TArfB=TA0;krfB=krf0;
        imrfgC=img00;TArfC=TA00;krfC=krf00;
        imvEold=imzc;rc=0;
    end
    
    if exist([matpth,'D\',nm,'mat'],'file') %&& rc==0
        % load and create immv
        disp('   Registration already calculated');disp('')
        load([matpth,nm,'mat'],'tform','cent','f');
        
        immvGg=register_global_im(immvg,tform,cent,f,mode(immvg(:)));
        TAmvG=register_global_im(TAmv,tform,cent,f,0);
    else
        rc=1;
        RB=0.4;RC=0.4;immvGgB=immvg;immvGgC=immvg;
        if IHC==1;ct=0.8;else;ct=0.945;end
        % try registration pairs 1
        [immvGg,tform,cent,f,R]=calculate_global_reg(imrfgA,immvg,rsc,iternum,IHC);
        % try with registration pairs 2
        if R<ct;[immvGgB,tformB,centB,fB,RB]=calculate_global_reg(imrfgB,immvg,rsc,iternum,IHC);disp('RB');end % R<0.93
        % try with registration pairs 3
        if R<ct && RB<ct;[immvGgC,tformC,centC,fC,RC]=calculate_global_reg(imrfgC,immvg,rsc,iternum,IHC);disp('RC');end %R<0.93
        %figure(17);imshowpair(imrfgA,immvGg),title(R)
%         figure(17);
%             subplot(1,3,1),imshowpair(imrfgA,immvGg),title(R)
%             subplot(1,3,2),imshowpair(imrfgB,immvGgB),title(RB)
%             subplot(1,3,3),imshowpair(imrfgC,immvGgC),title(RC)
%             ha=get(gcf,'children');linkaxes(ha);

        % use best of three global registrations
        disp([R RB RC]);disp('')
        RR=[R RB RC];
        [~,ii]=max(RR);disp(RR)
        if ii==1
            imrfg=imrfgA;TArf=TArfA;krf=krfA;disp('chose image A')
        elseif ii==2
            immvGg=immvGgB;tform=tformB;cent=centB;f=fB;disp('chose image B')
            imrfg=imrfgB;TArf=TArfB;krf=krfB;
        else
            immvGg=immvGgC;tform=tformC;cent=centC;f=fC;disp('chose image C')
            imrfg=imrfgC;TArf=TArfC;krf=krfC;
        end

        % save global registration data
        save([matpth,nm,'mat'],'tform','f','cent','szz','padall','krf');
        immvG=register_global_im(immv,tform,cent,f,fillval);
        TAmvG=register_global_im(TAmv,tform,cent,f,0);
        imwrite(immvG,[outpthG,nm,tpout]);
        
        disp('elastic')
        % elastic registration
        if exist([matpth,'D\',nm,'mat'],'file')
            load([matpth,'D\',nm,'mat'],'Dmv');
        else
            Dmv=calculate_elastic_registration(imrfg,immvGg,TArf,TAmvG,regE.szE,regE.bfE,regE.diE);
            if kk==1;D=zeros(size(Dmv));save([matpth,'D\',imlist(krf).name(1:end-3),'mat'],'D');end
        end
        load([matpth,'D\',imlist(krf).name(1:end-3),'mat'],'D');
        D=D+Dmv;
        save([matpth,'D\',nm,'mat'],'D','Dmv');

        D=imresize(D,size(immvG(:,:,1)));
        %Dnew=invert_D(D);im1=imwarp(immvG,D);im2=imwarp(im1,Dnew);figure,subplot(1,2,1),imshowpair(imzc,im1),subplot(1,2,2),imshowpair(immvG,im2);save([matpth,'D\Dnew\',nm,'mat'],'Dnew');
        immvE=imwarp(immvG,D,'nearest','FillValues',fillval);

        % save elastic registration data
        imwrite(immvE,[outpthE,nm,tpout]);
        imwrite(immvE(1:3:end,1:3:end,:),[outpthE2,nm,tpout]);


%             imvEold=imread([outpthE,imlist(krf).name(1:end-3),tpout]);
%             figure(17);
%                 subplot(1,2,1),imshowpair(imrfg,immvg)
%                 subplot(1,2,2),imshowpair(imcomplement(imvEold),imcomplement(immvE))
%                 ha=get(gcf,'children');linkaxes(ha);
        end
        
    % reset reference images
    imrfgC=imrfgB;TArfC=TArfB;krfC=krfB;
    imrfgB=imrfgA;TArfB=TArfA;krfB=krfA;
    imrfgA=immvGg;TArfA=TAmvG;krfA=mv(kk);
    if mv(kk)==mv(1);img0=immvGg;TA0=TAmvG;krf0=mv(kk);end
    try if mv(kk)==mv(2);img00=immvGg;TA00=TAmvG;krf00=mv(kk);end;catch;end
    
    toc(t1);
end
warning('on','all');

end
