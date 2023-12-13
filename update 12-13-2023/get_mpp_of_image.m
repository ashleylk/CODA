function mpp=get_mpp_of_image(pth,nm)

if contains(nm,'.ndpi')
    a=imfinfo([pth,nm]);
    tmp=a(1).XResolution;
    sxNDPI=(1./tmp).*10000;
    mpp=sxNDPI;
elseif contains(nm,'.svs')
    a=imfinfo([pth,nm]);
    tmp=a(1).ImageDescription;
    b1=strfind(tmp,'|MPP = ');
    b2=strfind(tmp,'|');
    b2=b2(find(b2>b1,1,'first'));
    if isempty(b2);b2=length(tmp)+1;end
    sxSVS=str2double(tmp(b1+6:b2-1));
    mpp=sxSVS;
end