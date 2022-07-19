function im=pad_im_both(im,sz,ext,fillval)
if nargin<4;fillval=squeeze(mode(mode(im,2),1))';end
if nargin<3;ext=0;end

     
    if size(im,1)>sz(1);im=im(1:sz(1),:,:);end
    if size(im,2)>sz(2);im=im(:,1:sz(2),:);end

    szim=[sz(1)-size(im,1) sz(2)-size(im,2)];
    szim(szim<0)=0;
    if size(im,3)==3
        if length(fillval)==1;fillval=[fillval fillval fillval];end
        ima=padarray(im(:,:,1),szim,fillval(1),'post');
        imb=padarray(im(:,:,2),szim,fillval(2),'post');
        imc=padarray(im(:,:,3),szim,fillval(3),'post');
        ima=padarray(ima,[ext ext],fillval(1),'both');
        imb=padarray(imb,[ext ext],fillval(2),'both');
        imc=padarray(imc,[ext ext],fillval(3),'both');
        im=cat(3,ima,imb,imc);
    else
        im=padarray(im,szim,fillval,'post');
        im=padarray(im,[ext ext],fillval,'both');
    end

%     szim=[sz(1)-size(im,1) sz(2)-size(im,2)];
%     szA=floor(szim/2);
%     szB=szim-szA+ext;
%     szA=szA+ext;
%     if size(im,3)==3
%         if length(fillval)==1;fillval=[fillval fillval fillval];end
%         ima=padarray(im(:,:,1),szA,fillval(1),'pre');
%         imb=padarray(im(:,:,2),szA,fillval(2),'pre');
%         imc=padarray(im(:,:,3),szA,fillval(3),'pre');
%         ima=padarray(ima,szB,fillval(1),'post');
%         imb=padarray(imb,szB,fillval(2),'post');
%         imc=padarray(imc,szB,fillval(3),'post');        
%         im=cat(3,ima,imb,imc);
%     else
%         im=padarray(im,szA,fillval,'pre');
%         im=padarray(im,szB,fillval,'post');
%     end
    
end