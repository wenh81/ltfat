function [xo,N]=gabglasso(ttype,xi,lambda,group);
%GABGLASSO   group lasso estimate (hard/soft) in time-frequency domain
%   Usage:  xo=gabglasso(ttype,x,lambda,group);
%           [xo,N]=gabglasso(ttype,x,lambda,group));
%
%   GABGLASSO('hard',x,lambda,'time') will perform
%   time hard group thresholding on x, i.e. all time-frequency
%   columns whose norm less than lambda will be set to zero.
%
%   GABGLASSO('soft',x,lambda,'time') will perform
%   time soft thresholding on x, i.e. all time-frequency
%   columns whose norm less than lambda will be set to zero,
%   and those whose norm exceeds lambda will be multiplied
%   by (1-lambda/norm).
%
%   GABGLASSO(ttype,x,lambda,'frequency') will perform
%   frequency thresholding on x, i.e. all time-frequency
%   rows whose norm less than lambda will be soft or hard thresholded
%   (see above).
%
%   [xo,N]=GABGLASSO(ttype,x,lambda,group) additionally returns
%   a number N specifying how many numbers where kept.
%
%   The function may meaningfully be applied to output from DGT, WMDCT or
%   from WIL2RECT(DWILT(...)).
%
%   See also:  gablasso, gabelasso
%
%   Demos: demo_audioshrink

%   AUTHOR : Bruno Torresani.  
%   REFERENCE: OK

narginchk(4,4);
  
NbFreqBands = size(xi,1);
NbTimeSteps = size(xi,2);

xo = zeros(size(xi));

switch(lower(group))
 case {'time'}
  for t=1:NbTimeSteps,
    threshold = norm(xi(:,t));
    mask = (1-lambda/threshold);
    if(strcmp(ttype,'soft'))
      mask = mask * (mask>0);
    elseif(strcmp(ttype,'hard'))
      mask = (mask>0);
    end
    xo(:,t) = xi(:,t) * mask;
  end
 case {'frequency'}
  for f=1:NbFreqBands,
    threshold = norm(xi(f,:));
    mask = (1-lambda/threshold);
    mask = mask * (mask>0);
    if(strcmp(ttype,'soft'))
      mask = mask * (mask>0);
    elseif(strcmp(ttype,'hard'))
      mask = (mask>0);
    end
    xo(f,:) = xi(f,:) * mask;
  end
 otherwise
  error('"group" parameter must be either "time" or "frequency".'); 
end

if nargout==2
    signif_map = (abs(xo)>0);
    N = sum(signif_map(:));
end
    


