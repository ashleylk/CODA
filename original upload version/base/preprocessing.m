function [im,impg,TA,fillval]=preprocessing(im,TA,szz,padall,IHC)
    % pad image
    fillval=squeeze(mode(mode(im,2),1))';
    if IHC==2;fillval=[241 241 241];end
    if IHC==5;fillval=[0 0 0];end
    if ~isempty(padall)
        im=pad_im_both2(im,szz,padall,fillval);
        if size(TA,1)~=size(im,1) || size(TA,2)~=size(im,2)
            TA=pad_im_both2(TA,szz,padall,0);
        end
    end
    
    % remove noise and complement images
    TA=TA>0;
    if ~isa(im,'uint8')
        im=im2uint8(im);
    end
    
    if IHC==2
        impg=rgb2gray(im);
        TA=ones(size(im(:,:,1)));
    elseif IHC==5
        impg=imcomplement(rgb2gray(im));
        %TA=ones(size(im(:,:,1)));fillval=0;
    elseif size(im,3)==3
        ima=im(:,:,1);ima(~TA)=255;
        imb=im(:,:,2);imb(~TA)=255;
        imc=im(:,:,3);imc(~TA)=255;
        imp=cat(3,ima,imb,imc);
        impg=imcomplement(rgb2gray(imp));
    else
        imp=im;
        imp(~TA)=255;
        impg=imcomplement(imp);
    end
    
    
    impg=imgaussfilt(impg,2);
end