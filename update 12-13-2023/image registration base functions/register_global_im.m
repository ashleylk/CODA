function imG=register_global_im(im,tform,cent,f,fillval)
% applies previously calculated global image registration to an image
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

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


