function im=pad_im_both2(im,sz,ext,fillval)
% pads histological images with whitespace to make files the same size for use in nonlinear image registration algorithm
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if nargin<4;fillval=squeeze(mode(mode(im,2),1))';end
if nargin<3;ext=0;end

    szim=[sz(1)-size(im,1) sz(2)-size(im,2)];
    szA=floor(szim/2);
    szB=szim-szA+ext;
    szA=szA+ext;
    if size(im,3)==3
        if length(fillval)==1;fillval=[fillval fillval fillval];end
        ima=padarray(im(:,:,1),szA,fillval(1),'pre');
        imb=padarray(im(:,:,2),szA,fillval(2),'pre');
        imc=padarray(im(:,:,3),szA,fillval(3),'pre');
        ima=padarray(ima,szB,fillval(1),'post');
        imb=padarray(imb,szB,fillval(2),'post');
        imc=padarray(imc,szB,fillval(3),'post');        
        im=cat(3,ima,imb,imc);
    else
        try
            im=padarray(im,szA,fillval,'pre');
        catch
            disp('fds')
        end
        try im=padarray(im,szB,fillval,'post');
        catch
            disp('vcxzfezrs')
        end
    end
end