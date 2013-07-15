function demo_equalizer(source,varargin)
%DEMO_EQUALIZER Real-time equalizer demonstration
%   Usage: demo_equalizer('gspi.wav')
%          demo_equalizer('playrec')
%
%   This demonstration shows an example of a octave parametric
%   equalizer. See chapter 5.2 in the book by Zolzer.
% 
%   References: zolz08

if nargin<1
   fprintf(['%s: To run the demo, use one of the following:\n',...
          'demo_equalizer(''gspi.wav'') to play gspi.wav (any wav file will do).\n',...
          'demo_equalizer(''playrec'') to record from a mic and play processed simultaneously.\n']...
          ,upper(mfilename));
    return;
end


% Buffer length
% Larger the number the higher the processing delay. 1024 with fs=44100Hz
% makes ~23ms.
% The value can be any positive integer.
% Note that the processing itself can introduce additional delay.
bufLen = 1024;

% Quality parameter of the peaking filters
Q = sqrt(2);

% Filters 
filts = [
         struct('Hb',[1;0],'Ha',[1;0],'G',0,'Z',[0;0],'type','lsf'),...
         struct('Hb',[1;0;0],'Ha',[1;0;0],'G',0,'Z',[0;0],'type','peak'),...
         struct('Hb',[1;0;0],'Ha',[1;0;0],'G',0,'Z',[0;0],'type','peak'),...
         struct('Hb',[1;0;0],'Ha',[1;0;0],'G',0,'Z',[0;0],'type','peak'),...
         struct('Hb',[1;0;0],'Ha',[1;0;0],'G',0,'Z',[0;0],'type','peak'),...
         struct('Hb',[1;0;0],'Ha',[1;0;0],'G',0,'Z',[0;0],'type','hsf')...
        ];
     
     
% Control pannel (Java object)
% Each entry determines one parameter to be changed during the main loop
% execution.

pcell = cell(1,numel(filts));
for ii=1:numel(filts)
   pcell{ii} =  {sprintf('band%i',ii),'Gain',-10,10,filts(ii).G,41};
end
p = blockpanel(pcell); 

% Setup blocktream
fs = block(source,varargin{:},'loadind',p);

% Cutoff/center frequency
feq = [0.0060, 0.0156, 0.0313, 0.0625, 0.1250, 0.2600]*fs;

% To allow the Java object initialize properly
pause(0.1);

% Build the filters
[filts(1).Ha, filts(1).Hb] = parlsf(feq(1),p.getParam('band1'),fs);
[filts(2).Ha, filts(2).Hb] = parpeak(feq(2),Q,p.getParam('band2'),fs);
[filts(3).Ha, filts(3).Hb] = parpeak(feq(3),Q,p.getParam('band3'),fs);
[filts(4).Ha, filts(4).Hb] = parpeak(feq(4),Q,p.getParam('band4'),fs);
[filts(5).Ha, filts(5).Hb] = parpeak(feq(5),Q,p.getParam('band5'),fs);
[filts(6).Ha, filts(6).Hb] = parhsf(feq(6),p.getParam('band6'),fs);

flag = 1;
%Loop until end of the stream (flag) and until panel is opened
while flag && p.flag
   
  % Obtain gains of the respective filters
  G = blockpanelget(p,'band1','band2','band3','band4','band5','band6');
  
  % Check if any of the user-defined gains is different from the actual ones
  % and do recomputauion.
   for ii=1:numel(filts)
     if G(ii)~=filts(ii).G
        filts(ii).G = G(ii);
        if strcmpi('lsf',filts(ii).type)
           [filts(ii).Ha, filts(ii).Hb] = parlsf(feq(ii),filts(ii).G,fs);
        elseif strcmpi('hsf',filts(ii).type)
           [filts(ii).Ha, filts(ii).Hb] = parhsf(feq(ii),filts(ii).G,fs);
        elseif strcmpi('peak',filts(ii).type)
           [filts(ii).Ha, filts(ii).Hb] = parpeak(feq(ii),Q,filts(ii).G,fs);   
        else
           error('Uknown filter type.');
        end
     end
  end
       
  % Read block of length bufLen
  [f,flag] = blockread(bufLen);
 
  % Do the filtering. Output of one filter is passed to the input of the
  % following filter. Internal conditions are used. 
  for ii=1:numel(filts)
    [f,filts(ii).Z] = filter(filts(ii).Ha,filts(ii).Hb,f,filts(ii).Z);
  end

  % Play the block
  blockplay(f);
end
% Close the control panel
p.close();
%fobj.close();

function [Ha,Hb]=parlsf(fc,G,Fs)
% PARLSF Parametric Low-Shelwing filter
%   Input parameters:
%         fm    : Cut-off frequency
%         G     : Gain in dB
%         Fs    : Sampling frequency
%   Output parameters:
%         Ha    : Transfer function numerator coefficients.
%         Hb    : Transfer function denominator coefficients.
%
%  For details see Table 5.4 in the reference.
Ha = zeros(3,1);
Hb = zeros(3,1);
%b0
Hb(1) = 1;
Ha(1) = 1;
K = tan(pi*fc/Fs);
if G>0
   V0=10^(G/20);
   den = 1 + sqrt(2)*K + K*K;
   % a0
   Ha(1) = (1+sqrt(2*V0)*K+V0*K*K)/den;
   % a1
   Ha(2) = 2*(V0*K*K-1)/den;
   % a2
   Ha(3) = (1-sqrt(2*V0)*K+V0*K*K)/den;
   % b1
   Hb(2) = 2*(K*K-1)/den;
   % b2
   Hb(3) = (1-sqrt(2)*K+K*K)/den;
elseif G<0
   V0=10^(-G/20);
   den = 1 + sqrt(2*V0)*K + V0*K*K;
   % a0
   Ha(1) = (1+sqrt(2)*K+K*K)/den;
   % a1
   Ha(2) = 2*(K*K-1)/den;
   % a2
   Ha(3) = (1-sqrt(2)*K+K*K)/den;
   % b1
   Hb(2) = 2*(V0*K*K-1)/den;
   % b2
   Hb(3) = (1-sqrt(2*V0)*K+V0*K*K)/den;
end

function [Ha,Hb]=parpeak(fc,Q,G,Fs)
% PARLSF Parametric Peaking filter
%   Input parameters:
%         fm    : Cut-off frequency
%         Q     : Filter quality. Q=fc/B, where B is filter bandwidth.
%         G     : Gain in dB
%         Fs    : Sampling frequency
%   Output parameters:
%         Ha    : Transfer function numerator coefficients.
%         Hb    : Transfer function denominator coefficients.
%
%  For details see Table 5.3 in the reference.
Ha = zeros(3,1);
Hb = zeros(3,1);
%b0
Hb(1) = 1;
Ha(1) = 1;
K = tan(pi*fc/Fs);
if G>0
   V0=10^(G/20);
   den = 1 + K/Q + K*K;
   % a0
   Ha(1) = (1+V0*K/Q+K*K)/den;
   % a1
   Ha(2) = 2*(K*K-1)/den;
   % a2
   Ha(3) = (1-V0*K/Q+K*K)/den;
   % b1
   Hb(2) = 2*(K*K-1)/den;
   % b2
   Hb(3) = (1-K/Q+K*K)/den;
elseif G<0
   V0=10^(-G/20);
   den = 1 + V0*K/Q + V0*K*K;
   % a0
   Ha(1) = (1+K/Q+K*K)/den;
   % a1
   Ha(2) = 2*(K*K-1)/den;
   % a2
   Ha(3) = (1-K/Q+K*K)/den;
   % b1
   Hb(2) = 2*(K*K-1)/den;
   % b2
   Hb(3) = (1-V0*K/Q+K*K)/den;
end

function [Ha,Hb]=parhsf(fm,G,Fs)
% PARLSF Parametric High-shelving filter
%   Input parameters:
%         fm    : Cut-off frequency
%         G     : Gain in dB
%         Fs    : Sampling frequency
%   Output parameters:
%         Ha    : Transfer function numerator coefficients.
%         Hb    : Transfer function denominator coefficients.
%
%  For details see Table 5.3 in the reference.
Ha = zeros(3,1);
Hb = zeros(3,1);
%b0
Hb(1) = 1;
Ha(1) = 1;
K = tan(pi*fm/Fs);
if G>0
   V0=10^(G/20);
   den = 1 + sqrt(2)*K + K*K;
   % a0
   Ha(1) = (V0+sqrt(2*V0)*K+K*K)/den;
   % a1
   Ha(2) = 2*(K*K-V0)/den;
   % a2
   Ha(3) = (V0-sqrt(2*V0)*K+K*K)/den;
   % b1
   Hb(2) = 2*(K*K-1)/den;
   % b2
   Hb(3) = (1-sqrt(2)*K+K*K)/den;
elseif G<0
   V0=10^(-G/20);
   den = V0 + sqrt(2*V0)*K + K*K;
   % a0
   Ha(1) = (1+sqrt(2)*K+K*K)/den;
   % a1
   Ha(2) = 2*(K*K-1)/den;
   % a2
   Ha(3) = (1-sqrt(2)*K+K*K)/den;
   % b1
   Hb(2) = 2*(K*K/V0-1)/den;
   % b2
   Hb(3) = (1-sqrt(2/V0)*K+K*K/V0)/den;
end




