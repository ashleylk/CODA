function calculate_tissue_ws(pth,calc_style)
% calculates the tissue space of histological images for use in a nonlinear image registration algorithm
% INPUTS:
% 1. pth: folder containing tif images that you want to make a tissue mask for
% 2. calc_style: method to calculate TA. First try 1. if they look weird, try 2
% OUTPUTS: 
% in a subfolder of pth called 'TA', the code will save a logical tif image where tissue space is ==1
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if pth(end)~='\';pth=[pth,'\'];end
imlist=dir([pth,'*tif']);
outpth=[pth,'TA\'];
if ~isfolder(outpth);mkdir(outpth);end
if ~exist('calc_style','var');calc_style=1;end

for k=1:length(imlist)
    nm=imlist(k).name;
    disp(['calculating whitespace for image ',num2str(k),' of ',num2str(length(imlist)),': ',nm])
    if exist([outpth,nm],'file');disp('  already done');continue;end
    im0=imread([pth,nm]);

    im=double(im0);
    
    if calc_style==1
        img=rgb2gray(im0);
        img=img==255 | img==0;
        im(cat(3,img,img,img))=NaN;
        fillval=squeeze(mode(mode(im,2),1))';
        ima=im(:,:,1);imb=im(:,:,2);imc=im(:,:,3);
        ima(img)=fillval(1);imb(img)=fillval(2);imc(img)=fillval(3);
        im=cat(3,ima,imb,imc);

        % remove objects with very small standard deviations
        disp('H&E image')
        TA=im-permute(fillval,[1 3 2]);
        TA=mean(abs(TA),3)>10;
        
        % remove large black objects (these are probably shadows or dust
        black_line=imclose(std(im,[],3)<5 & rgb2gray(im0)<160,strel('disk',2));
        TA=TA & ~black_line;
        TA=imclose(TA,strel('disk',4));
    else
        TA=im(:,:,2)<210;
        TA=imclose(TA,strel('disk',4));
        TA=bwareaopen(TA,10);
    end
    TA=imfill(TA,'holes');
    
    % remove objects that are less than 1/10 largest object size
    TA=bwlabel(TA);
    N=histcounts(TA(:),max(TA(:))+1);
    N(1)=0;
    N(N<(max(N)/20))=0;
    N(N>0)=1;
    TA=N(TA+1); 
    
    imwrite(TA,[outpth,nm]);
    disp('  done');

end
