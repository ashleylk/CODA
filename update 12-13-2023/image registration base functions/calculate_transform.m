function res=calculate_transform(im,imnxt,xy,p)
% estimate the dislocation of images between frames.
%  using PIV. 
% 
% input: im : current image (required)
% imnxt: image at next frame,(required)
% p : parameters settings
%
% developed by Pei-Hsun Wu, Ph.D
%  @ johns Hopkins University, INBT,  0/20/2014;

    [imly,imlx]=size(im); 
    [imly2,imlx2]=size(imnxt);
    imly=min(imly,imly2);
    imlx=min(imlx,imlx2);
if nargin<3 || isempty(xy)
    xy=floor([(imly-1)/2, (imlx-1)/2])+1; % using center point of a image
end   

if nargin<4 || isempty(p)  
    p.rm=floor([imly-1,imlx-1]/2);
    p.rm=round(p.rm*0.95); % for excluding edge effect % added 6/2/2016
    p.rs=floor(p.rm); 
    p.tm=3;        
    p.rg=max([imly,imlx]); % search range
end
        
       x0=xy(2); % location of image pattern
       y0=xy(1); 
                                 
           imptn=im((y0-p.rm(1):y0+p.rm(1)),(x0-p.rm(2):x0+p.rm(2))) ;
           imgrid=imnxt((y0-p.rs(1):y0+p.rs(1)),(x0-p.rs(2):x0+p.rs(2))) ;
           
           % intenitsy normalization
           % this might help to take off scale effect;
           % this help a lot. especially for fft based transformation
           imptn=(imptn-mean(imptn))/std(imptn(:));
           imgrid=(imgrid-mean(imgrid))/std(imgrid(:));
           
% decide pattern recognization method  
            switch(p.tm)
                case(1); y1=xcorr2(imgrid,imptn);
                case(2); y1=patrecog(imgrid,imptn);
                case(3); y1=xcorrf2(imptn,imgrid);
                case(4); y1=xcor2d_nmrd(imgrid,imptn);
                case(5); y1=normxcorr2(imptn,imgrid); y1=y1(end:-1:1,end:-1:1)*100; % rescale to larger htan 1
            end

            msk=mskcircle2_rect(size(y1),p.rg);
            y1m=y1.*msk;
            [my,mx]=find(y1m==max(y1m(:)));   % pixel resolution;             
            [cnt]=gcnt(y1,[mx(1),my(1)],3,0,0);    
            yx=cnt([2 1]);
            res=yx-p.rs-p.rm-1;
            res=res([2 1]); % xy
 