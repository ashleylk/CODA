function [chgi,imH,imE,imbg,imboth]=colordeconv2pw4_log10(sampleRGB,staintype,assignedOD)
% sample RGB is input image
% staintype == 'he' or 'ihc'
% abs == 3x3 matrix. 
%   each row is rgb absorbance for 1 of 3 channels to deconvolve
% OD = -log((intenisty+1)/256);
% intensity= 256*exp(-OD)-1
    
defaultHNE=  [0.5960 0.7555 0.2650; ...    % Mean of above
             0.1790 0.9415 0.2725;...
             0.5855 0.3565 0.6130];       

defaultIHC= [0.6500 0.7040 0.2860; ... 
             0.2681 0.5703 0.7764;...
             0.7110 0.4232 0.5616];
defaultIHC(3,:)=1-(defaultIHC(1,:)+defaultIHC(2,:))/2;
defaultDUAL= [0.6633 0.5700 0.4849;...
              0.4839 0.4875 0.7267;...
              0.4048 0.7454 0.5296];
     
defaultcolorout=defaultHNE;
defaultcolor=defaultHNE;

if nargin==0
    error('Need input image')
elseif nargin == 1
    defaultcolor=defaultHNE;
    % assume H&E stain % optical density space
  
elseif nargin == 2
    % use assumed values for H&E, ihc, or dual ihc stain
    if staintype=="ihc"
        defaultcolor=defaultIHC;
        defaultcolorout=defaultIHC; 
    elseif staintype=="he"
        defaultcolor=defaultHNE; 
    elseif staintype=="dual"
        defaultcolor=defaultDUAL;  
        defaultcolorout=defaultIHC;
    else
        error('staintype should be he, ihc, or dual')
    end
elseif nargin == 3
    defaultcolor=assignedOD;
    
end

    He = defaultcolor(1,:)';
    Eo = defaultcolor(2,:)';
    BG = defaultcolor(3,:)';

% [height, width, channel] = size(sampleRGB);
% sample_deinterlace=sampleRGB;
% H_deinterlace = [0 1 0; 0 2 0; 0 1 0] ./4;
% sample_deinterlace = zeros(height, width, channel);
% for k=1:channel
%     sample_deinterlace(:,:,k) = filter2(H_deinterlace,double(sampleRGB(:,:,k)),'same');
% end

% [rgbgjh]=get_jointhist3dW2(sampleRGB(:,:,1),sampleRGB(:,:,2),sampleRGB(:,:,3),0:255,0:255,0:255);
% [uR,uG,uB]=find(rgbjh==1);


sampleRGB=single(sampleRGB);
colormix=sampleRGB(:,:,1)+256*sampleRGB(:,:,2)+256^2*sampleRGB(:,:,3); 

[uniquecolors,~,u3]=unique(colormix);
uR=mod(uniquecolors,256);
uG=mod(floor(uniquecolors/256),256);
uB=mod(floor(uniquecolors/256^2),256);

sampleRGB_OD = -log10((cat(3,uR,uG,uB)+1)./256);


% ODs=-log([0:255]+1/256); % get all possible OD number
% get all existing pairs of ODs in images;
% sampleRGB_OD(:,:,1)

% Create Deconvolution matrix
M = [He/norm(He) Eo/norm(Eo) BG/norm(BG)];
% M=[He Eo BG];
D = inv(M);

sampleHEB_OD=[];
RGB=im2mat(sampleRGB_OD)';
% toc;
        HEB = D * RGB; % this step need to prevent; only calculated possible RGB combo instead all;
        HEB = HEB'; % main output
        % matchback from uniqe color space to image color space;
        
%             toc;
        	H = reshape(HEB(u3,1),size(colormix));
            E = reshape(HEB(u3,2),size(colormix));
            bg = reshape(HEB(u3,3),size(colormix));
%       	sampleHEB_OD(:,:,1) = reshape(HEB(:,1),size(sampleRGB_OD(:,:,1)));
%        	sampleHEB_OD(:,:,2) = reshape(HEB(:,2),size(sampleRGB_OD(:,:,1)));
%        	sampleHEB_OD(:,:,3) = reshape(HEB(:,3),size(sampleRGB_OD(:,:,1)));
%             toc;
chgi={};
chgi{1}=H;
chgi{2}=E;
chgi{3}=bg;
           
% H = sampleHEB_OD(:,:,1);
% E = sampleHEB_OD(:,:,2);
% bg = sampleHEB_OD(:,:,3);

% output intensities of channels for ihc

    He = defaultcolorout(1,:)';
    Eo = defaultcolorout(2,:)';
    BG = defaultcolorout(3,:)';

% convert to color images
[x,y]=size(H);
imH=zeros([x,y,3]);
imE=zeros([x,y,3]);
imbg=zeros([x,y,3]);
imboth=zeros([x,y,3]);

if nargout>1
    %for q=1:3
    %    imH(:,:,q)=exp(-H*He(q))*256-1; % including the background channel help the color show
    %    imE(:,:,q)=exp(-E*Eo(q))*256-1;
    %    imbg(:,:,q)=exp(-bg*BG(q))*256-1;
    %    imboth(:,:,q)=exp(-H*He(q)-E*Eo(q)-bg*BG(q))*256-1;
    %end
    for q=1
        imH=10.^(-H)*256-1; % including the background channel help the color show
        imE=10.^(-E)*256-1;
        imbg=10.^(-bg)*256-1;
        imboth=10.^(-H-E-bg)*256-1;
    end
    imH=uint8(imH);
    imE=uint8(imE);
    imbg=uint8(imbg);
    imboth=uint8(imboth);
end
% output individaul channel

if 0
% display
figure
subplot(2,1,1),imshow(sampleRGB),axis equal;axis off;title('original')
subplot(2,1,2),imshow(imboth);title('reconstructed')
ha2=get(gcf,'children');
linkaxes(ha2)

figure(1)
subplot(1,2,1),imshow(imH),axis equal;axis off;title('Hemotoxylin')
subplot(1,2,2),imshow(imE),axis equal;axis off;title('DAB or Eosin')
ha2=get(gcf,'children');
linkaxes(ha2)
end