function res = bpassW(arr,lnoise,lobject)
% bandpass filter. 
% 
% Written by  Pei-Hsun Wu, 
% Post-doc associate, @ JHU, INBT.

  b = double(lnoise);
  w = round(lobject); 
N=2*w+1;
hg=fspecial('gaussian',N, b*sqrt(2));
arrg = imfilter(arr,hg,'symmetric','conv') ;
ha = fspecial('average',N);
arra = imfilter(arr,ha,'symmetric','conv');
rest = max(arrg-arra,0);
res=rest;