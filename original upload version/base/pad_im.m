function im=pad_im_both(im,sz,ext)
    
    szim=[sz(1)-size(im,1) sz(2)-size(im,2)];
    
    if size(im,3)==3
        
        a0=im(:,:,1);a=mode(a0(:));
        b0=im(:,:,2);b=mode(b0(:));
        c0=im(:,:,3);c=mode(c0(:));
        ima=padarray(a0,szim,a,'post');
        imb=padarray(b0,szim,b,'post');
        imc=padarray(c0,szim,c,'post');
        
        ima=padarray(ima,ext,a,'both');
        imb=padarray(imb,ext,b,'both');
        imc=padarray(imc,ext,c,'both');
        
        im=cat(3,ima,imb,imc);
    else
        a=mode(im(:));
        im=padarray(im,szim,a,'post');
        im=padarray(im,ext,a,'both');
    end
end