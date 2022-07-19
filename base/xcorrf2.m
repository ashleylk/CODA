function c = xcorrf2(a,b,pad)
%  c = xcorrf2(a,b)
%   Two-dimensional cross-correlation using Fourier transforms.
%       XCORRF2(A,B) computes the crosscorrelation of matrices A and B.
%       XCORRF2(A) is the autocorrelation function.
%       This routine is functionally equivalent to xcorr2 but usually faster.
%       See also XCORR2.

%       Author(s): R. Johnson
%       $Revision: 1.0 $  $Date: 1995/11/27 $

  if nargin<3
    pad='yes';
  end
  
  
  [ma,na] = size(a);
  if nargin == 1
    %       for autocorrelation
    b = a;
  end
  [mb,nb] = size(b);
  %       make reverse conjugate of one array
  b = conj(b(mb:-1:1,nb:-1:1));
  
  if strcmp(pad,'yes');
    %       use power of 2 transform lengths
    mf = 2^nextpow2(ma+mb);
    nf = 2^nextpow2(na+nb);
    at = fft2(b,mf,nf);
    bt = fft2(a,mf,nf);
  elseif strcmp(pad,'no');
    at = fft2(b);
    bt = fft2(a);
  else
    disp('Wrong input to XCORRF2'); return
  end
  
  %       multiply transforms then inverse transform
  c = ifft2(at.*bt);
  %       make real output for real input
  if ~any(any(imag(a))) & ~any(any(imag(b)))
    c = real(c);
  end
  %  trim to standard size
  
  if strcmp(pad,'yes');
    c(ma+mb:mf,:) = [];
    c(:,na+nb:nf) = [];
  elseif strcmp(pad,'no');
    c=fftshift(c(1:end-1,1:end-1));
    
%    c(ma+mb:mf,:) = [];
%    c(:,na+nb:nf) = [];
  end
