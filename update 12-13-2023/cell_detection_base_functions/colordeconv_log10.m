function [chgi,imH,imE,imbg,imboth]=colordeconv_log10(sampleRGB,assignedOD)
% sample RGB is input image
% abs == 3x3 matrix. 
%   each row is rgb absorbance for 1 of 3 channels to deconvolve
% OD = -log((intenisty+1)/256);
% intensity= 256*exp(-OD)-1

    defaultcolor=assignedOD;


    He = defaultcolor(1,:)';
    Eo = defaultcolor(2,:)';
    BG = defaultcolor(3,:)';
    sampleRGB=single(sampleRGB);
    colormix=sampleRGB(:,:,1)+256*sampleRGB(:,:,2)+256^2*sampleRGB(:,:,3); 

    [uniquecolors,~,u3]=unique(colormix);
    uR=mod(uniquecolors,256);
    uG=mod(floor(uniquecolors/256),256);
    uB=mod(floor(uniquecolors/256^2),256);

    sampleRGB_OD = -log10((cat(3,uR,uG,uB)+1)./256);

    % Create Deconvolution matrix
    M = [He/norm(He) Eo/norm(Eo) BG/norm(BG)];
    D = inv(M);

    RGB=im2mat(sampleRGB_OD)';

    HEB = D * RGB; % this step need to prevent; only calculated possible RGB combo instead all;
    HEB = HEB'; % main output
    % matchback from uniqe color space to image color space;
    H = reshape(HEB(u3,1),size(colormix));
    E = reshape(HEB(u3,2),size(colormix));
    bg = reshape(HEB(u3,3),size(colormix));
    chgi={};
    chgi{1}=H;
    chgi{2}=E;
    chgi{3}=bg;

    % convert to color images
    [x,y]=size(H);
    imH=zeros([x,y,3]);
    imE=zeros([x,y,3]);
    imbg=zeros([x,y,3]);
    imboth=zeros([x,y,3]);

    if nargout>1
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

