function imG=register_global_im(im,tform,cent,f,fillval)
    % set up rotation point of reference
    Rin=imref2d(size(im));
    Rin.XWorldLimits = Rin.XWorldLimits-cent(1);
    Rin.YWorldLimits = Rin.YWorldLimits-cent(2);

    % flip if necessary
    if f==1
        im=im(end:-1:1,:,:);
    end
    
    % register
    imG=imwarp(im,Rin,tform,'nearest','Outputview',Rin,'Fillvalues',fillval);

end


