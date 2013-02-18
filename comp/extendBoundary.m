function fout = extendBoundary(f,extLen,ext,varargin)
% 
a = 2;
if(~isempty(varargin))
    a = varargin{1};
end
fout = zeros(length(f) + 2*extLen,1);
fout(extLen+1:end-extLen) = f;

legalExtLen = min([length(f),extLen]);
timesExtLen = floor(extLen/length(f));
moduloExtLen = mod(extLen,length(f));

% zero padding by default
% ext: 'per','zpd','sym','symw','asym','asymw','ppd','sp0'
if(strcmp(ext,'perdec')) % possible last samples replications
    moda = mod(length(f),a);
    repl = a-moda;
    if(moda)
        % version with replicated last sample
        fout(end-extLen+1:end-extLen+repl) = f(end);
        fRepRange = 1+extLen:extLen+length(f)+repl;
        fRep = fout(fRepRange);
        fRepLen = length(fRepRange);
        timesExtLen = floor(extLen/fRepLen);
        moduloExtLen = mod(extLen,fRepLen);

        fout(1+extLen-timesExtLen*fRepLen:extLen) = repmat(fRep,timesExtLen,1);
        fout(1:moduloExtLen) = fRep(end-moduloExtLen+1:end);
        
        timesExtLen = floor((extLen-repl)/fRepLen);
        moduloExtLen = mod((extLen-repl),fRepLen);
        fout(end-extLen+repl+1:end-extLen+repl+timesExtLen*fRepLen) = repmat(fRep,timesExtLen,1);
        fout(end-moduloExtLen+1:end) = f(1:moduloExtLen);
        
        %fout(rightStartIdx:end-extLen+timesExtLen*length(f)) = repmat(f(:),timesExtLen,1);
        %fout(1+extLen-legalExtLen:extLen-repl)= f(end-legalExtLen+1+repl:end);
    else
        fout = extendBoundary(f,extLen,'per',varargin{:});
       % fout(1+extLen-legalExtLen:extLen) = f(end-legalExtLen+1:end);
       % fout(1:extLen-legalExtLen) = f(end-(extLen-legalExtLen)+1:end);
       % fout(end-extLen+1:end-extLen+legalExtLen) = f(1:legalExtLen);
    end
elseif(strcmp(ext,'per') || strcmp(ext,'ppd'))
       % if ext > length(f)
       fout(1+extLen-timesExtLen*length(f):extLen) = repmat(f(:),timesExtLen,1);
       fout(end-extLen+1:end-extLen+timesExtLen*length(f)) = repmat(f(:),timesExtLen,1);
       %  mod(extLen,length(f)) samples are the rest
       fout(1:moduloExtLen) = f(end-moduloExtLen+1:end);
       fout(end-moduloExtLen+1:end) = f(1:moduloExtLen);
elseif(strcmp(ext,'sym'))
    fout(1+extLen-legalExtLen:extLen) = f(legalExtLen:-1:1);
    fout(end-extLen+1:end-extLen+legalExtLen) = f(end:-1:end-legalExtLen+1);
elseif(strcmp(ext,'symw'))
    legalExtLen = min([length(f)-1,extLen]);
    fout(1+extLen-legalExtLen:extLen) = f(legalExtLen+1:-1:2);
    fout(end-extLen+1:end-extLen+legalExtLen) = f(end-1:-1:end-legalExtLen);
elseif(strcmp(ext,'asym'))
    fout(1+extLen-legalExtLen:extLen) = -f(legalExtLen:-1:1);
    fout(end-extLen+1:end-extLen+legalExtLen) = -f(end:-1:end-legalExtLen+1);
elseif(strcmp(ext,'asymw'))
    legalExtLen = min([length(f)-1,extLen]);
    fout(1+extLen-legalExtLen:extLen) = -f(legalExtLen+1:-1:2);
    fout(end-extLen+1:end-extLen+legalExtLen) = -f(end-1:-1:end-legalExtLen);
elseif(strcmp(ext,'sp0'))
    fout(1:extLen) = f(1);
    fout(end-extLen+1:end) = f(end);
end