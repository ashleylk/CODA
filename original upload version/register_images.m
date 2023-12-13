function register_images(pth,IHC,E,zc,szz,sk,tpout,regE)
% Rough registration of a series of 2D tumor sections cut along the 
% z axis.  Images will be warped into near-alignment
warning ('off','all');
if ~exist('sk','var');sk=1;end
if ~exist('E','var') || isempty(E);E=1;end
if ~exist('IHC','var') || isempty(IHC);IHC=0;end
if ~exist('tpout','var');tpout='tif';end
imlist=dir([pth,'*tif']);
if isempty(imlist);imlist=dir([pth,'*jp2']);end
if isempty(imlist);imlist=dir([pth,'*jpg']);end
tp=imlist(1).name(end-2:end);
if ~exist('zc','var') || isempty(zc);zc=ceil(length(imlist)/2);end
% calculate center image and order
rf=[zc:-sk:2 zc:sk:length(imlist)-1 0];
mv=[zc-sk:-sk:1 zc+sk:sk:length(imlist)];

% elastic registration settings
if ~exist('regE','var')
    regE.szE=201; % size of registration tiles % 250
    regE.bfE=100; % size of buffer on registration tiles
    regE.diE=155; % distance between tiles     % 150
end

% find max size of images in list
if ~exist('szz','var')
    szz=[0 0];
    for kk=1:length(imlist)
        inf=imfinfo([pth,imlist(kk).name]);
        szz=[max([szz(1),inf.Height]) max([szz(2),inf.Width])]; 
    end
end

% global registration settings
padall=250; % padding around all images
if IHC==1;rsc=4;elseif IHC==10;rsc=2;else;rsc=6;end
iternum=5; % max iterations of registration calculation

% define outputs
outpthG=[pth,'registered\'];
outpthE=[outpthG,'elastic registration\'];
matpth=[outpthE,'save_warps\'];
mkdir(outpthG);mkdir(matpth);
if E;mkdir(outpthE);mkdir([matpth,'D\']);mkdir([matpth,'D\Dnew\']);end

% set up center image
nm=imlist(zc).name(1:end-3);
[imzc,TAzc]=get_ims(pth,nm,tp);
[imzc,imzcg,TAzc]=preprocessing(imzc,TAzc,szz,padall,IHC);
disp(['Reference image: ',nm])

% save reference image outputs
imwrite(imzc,[outpthG,nm,tpout]);
if E
    imwrite(imzc,[outpthE,nm,tpout]);
    D=zeros([size(imzc(:,:,1)) 2]);
    save([matpth,'D\',nm,'mat'],'D');
end

img=imzcg;TA=TAzc;krf=zc;
img0=imzcg;TA0=TAzc;krf0=zc;
img00=imzcg;TA00=TAzc;krf00=zc;

for kk=1:length(mv)
    t1=tic;
    fprintf(['Image ',num2str(kk),' of ',num2str(length(imlist)-1),...
        '\n  reference image:  ',imlist(rf(kk)).name(1:end-4),...
        '\n  moving image:  ',imlist(mv(kk)).name(1:end-4),'\n']);
    % create moving image
    nm=imlist(mv(kk)).name(1:end-3);
    [immv0,TAmv]=get_ims(pth,nm,tp);
    [immv,immvg,TAmv,fillval]=preprocessing(immv0,TAmv,szz,padall,IHC);
    
    % reset reference images when at center
    if rf(kk)==zc
        imrfgA=img;TArfA=TA;krfA=zc;
        imrfgB=img0;TArfB=TA0;krfB=krf0;
        imrfgC=img00;TArfC=TA00;krfC=krf00;
        imvEold=imzc;rc=0;
    end
    
    if exist([matpth,'D\',nm,'mat'],'file') && rc==0
        % load and create immv
        disp('   Registration already calculated');disp('')
        load([matpth,nm,'mat'],'tform','cent','f');
        
        immvGg=register_global_im(immvg,tform,cent,f,mode(immvg(:)));
        TAmvG=register_global_im(TAmv,tform,cent,f,0);
    else
        %[immv0,TAmv]=get_ims(pth,nm,tp,1);
        %[immv,immvg,TAmv,fillval]=preprocessing(immv0,TAmv,szz,padall,IHC);
        rc=1;
        RB=0.4;RC=0.4;immvGgB=immvg;immvGgC=immvg;
        % try registration pairs 1
        [immvGg,tform,cent,f,R]=calculate_global_reg(imrfgA,immvg,rsc,iternum,IHC);
        % try with registration pairs 2
        if R<0.92;[immvGgB,tformB,centB,fB,RB]=calculate_global_reg(imrfgB,immvg,rsc,iternum,IHC);disp('RB');end % R<0.93
        % try with registration pairs 3
        if R<0.92 && RB<0.92;[immvGgC,tformC,centC,fC,RC]=calculate_global_reg(imrfgC,immvg,rsc,iternum,IHC);disp('RC');end %R<0.93
        %figure(17);imshowpair(imrfgA,immvGg),title(R)
        figure(17);
            subplot(1,3,1),imshowpair(imrfgA,immvGg),title(R)
            subplot(1,3,2),imshowpair(imrfgB,immvGgB),title(RB)
            subplot(1,3,3),imshowpair(imrfgC,immvGgC),title(RC)
            ha=get(gcf,'children');linkaxes(ha);
        
        if contains(nm,'030_0620')
             disp('zcesacesag')
        end

        % use best of three global registrations
        %disp([R RB RC]);disp('')
        RR=[R RB RC];
        [~,ii]=max(RR);disp(RR)
        if ii==1
            imrfg=imrfgA;TArf=TArfA;krf=krfA;
        elseif ii==2
            immvGg=immvGgB;tform=tformB;cent=centB;f=fB;
            imrfg=imrfgB;TArf=TArfB;krf=krfB;
        else
            immvGg=immvGgC;tform=tformC;cent=centC;f=fC;
            imrfg=imrfgC;TArf=TArfC;krf=krfC;
        end

        % save global registration data
        save([matpth,nm,'mat'],'tform','f','cent','szz','padall');
        immvG=register_global_im(immv,tform,cent,f,fillval);
        TAmvG=register_global_im(TAmv,tform,cent,f,0);
        imwrite(immvG,[outpthG,nm,tpout]);
        
        if E
            disp('elastic')
            % elastic registration
            load([matpth,'D\',imlist(krf).name(1:end-3),'mat'],'D');
            if exist([matpth,'D\',nm,'mat'],'file')
                load([matpth,'D\',nm,'mat'],'Dmv');
            else
                Dmv=calculate_elastic_registrationC(imrfg,immvGg,TArf,TAmvG,regE.szE,regE.bfE,regE.diE);
            end
            D=D+Dmv;
            %Dnew=invert_D(D);im1=imwarp(immvG,D);im2=imwarp(im1,Dnew);figure,subplot(1,2,1),imshowpair(imzc,im1),subplot(1,2,2),imshowpair(immvG,im2);save([matpth,'D\Dnew\',nm,'mat'],'Dnew');
            immvE=imwarp(immvG,D,'nearest','FillValues',fillval);

            % save elastic registration data
            imwrite(immvE,[outpthE,nm,tpout]);
            save([matpth,'D\',nm,'mat'],'D','Dmv');
            
            
%             imvEold=imread([outpthE,imlist(krf).name(1:end-3),tpout]);
%             figure(17);
%                 subplot(1,2,1),imshowpair(imrfg,immvg)
%                 subplot(1,2,2),imshowpair(imcomplement(imvEold),imcomplement(immvE))
%                 ha=get(gcf,'children');linkaxes(ha);
        end
        
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


    % show images
%     imrfgE=imwarp(imrfg,D-Dmv,'nearest','FillValues',0);
%     figure(17);
%         subplot(1,3,1),imshowpair(imrfg,immvg)
%         subplot(1,3,2),imshowpair(imrfg,immvGg)
%         subplot(1,3,3),imshowpair(imrfgE,imcomplement(immvE))
%         ha=get(gcf,'children');linkaxes(ha);