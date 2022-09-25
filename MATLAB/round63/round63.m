function [Y,idx,pns,edg,rnd] = round63(X,ser,rnd) %#ok<*ISMAT>
% Round numeric values to IEC 60063 E-Series (resistor and capacitor values).
%
% (c) 2014-2021 Stephen Cobeldick
%
% Round the input array values to standard electronic component values
% from any IEC 60063 series. The supported E-Series are E3, E6, E12, E24,
% E48, E96, and E192. For example E6 = [..10,15,22,33,47,68,100,150,220..].
% Reference: <https://en.wikipedia.org/wiki/E_series_of_preferred_numbers>
%
% To best match the component tolerance limits the rounding bin edges are
% calculated internally as the harmonic mean of adjacent E-Series values.
% Alternatively, the rounding bin edge calculation may be selected using
% option <rnd>: 'arithmetic', 'up', 'down', or 'harmonic' (default).
%
%%% Syntax:
%  Y = round63(X,ser)
%  Y = round63(X,ser,rnd)
%  [Y,idx,pns,edg] = round63(...)
%
% <X> must be a real numeric array or matrix: any negative, zero, infinite,
% or NaN elements in <X> are returned as NaN in both <Y> & <idx> outputs.
% <Y> contains the elements of <X> rounded to the values of the E-series
% selected by input <ser>. <idx> is an index of the rounded values in <Y>,
% such that Y = pns(idx). <pns> is a vector of contiguous E-Series values
% that includes all values of <Y>. <edg> is the vector of bin-edges that
% were used to bin the <X> values, and is generated from the <pns> values
% according to the reqiested <rnd> option.
%
%% Examples %%
%
% >> round63(500, "E12")
% ans = 470
%
% >> round63([5,42,18,100], 'E12')
% ans = [4.7, 39, 18, 100]
%
% >> round63([5,42,18,100], 'E6') % default = 'harmonic'
% ans = [4.7, 47, 22, 100]
% >> round63([5,42,18,100], 'E6', 'up')
% ans = [6.8, 47, 22, 100]
% >> round63([5,42,18,100], 'E6', 'down')
% ans = [4.7, 33, 15, 100]
% >> round63([5,42,18,100], 'E6', 'arithmetic')
% ans = [4.7, 47, 15, 100]
%
% >> [Y,idx,pns,edg] = round63([5,42,18,100], 'E3')
% Y   = [4.7, 47, 22, 100]
% idx = [  1,  4,  3,   5]
% pns = [4.7; 10; 22; 47; 100]
% edg = [2.9971; 6.3946; 13.75; 29.971; 63.946; 137.5]
%
% >> [Y,idx,pns,edg] = round63([-Inf,Inf,NaN; -1, 0, 1], 'E3')
% Y   = [NaN, NaN, NaN; NaN, NaN, 1]
% idx = [NaN, NaN, NaN; NaN, NaN, 1]
% pns = 1
% edg = [0.63946; 1.375]
%
%% Input and Output Argumments %%
%
%%% Inputs (**=default):
%  X   = NumericArray (scalar/vector/matrix/ND), with values to be
%        rounded to IEC 60063 E-series preferred component values.
%  ser = CharVector or StringScalar, to select the E-series. Must be
%        one of 'E3', 'E6', 'E12', 'E24', 'E48', 'E96', or 'E192'.
%  rnd = CharVector or StringScalar, to select the rounding. Must be one
%        of 'arithmetic', 'up', 'down', 'harmonic'**, or their initials.
%
%%% Outputs:
%  Y   = Numeric, the same size as <X>, with values rounded to <ser> E-Series.
%  idx = Numeric, the same size as <X>, the index such that Y = pns(idx).
%  pns = Numeric Vector, contiguous E-Series values containing all <Y> values.
%  edg = Numeric Vector, the bin edges generated from adjacent <pns> values.
%
% See also ROUND63_VIEW ROUND63_TEST NUM2CIRCUIT NUM2SIP NUM2RKM ROUND HISTC HISTCOUNTS

%%% Input Wrangling %%%
%
assert(isnumeric(X)&&isreal(X),...
	'SC:round63:X:NotRealNumeric',...
	'First input <X> must be a real numeric array.')
%
ser = rst1s2c(ser);
assert(ischar(ser)&&ndims(ser)<3&&size(ser,1)==1,...
	'SC:round63:ser:NotText',...
	'Second input <ser> must be a string scalar or a 1xN character vector.')
%
if nargin<3
	rnd = 'harmonic';
else
	rnd = rst1s2c(rnd);
	assert(ischar(rnd)&&ndims(rnd)<3&&size(rnd,1)==1,...
		'SC:round63:rnd:NotText',...
		'Third input <rnd> must be a string scalar or a 1xN character vector.')
end
%
% Select IEC 60063 Preferred Number Sequence (PNS):
switch upper(ser)
	case 'E3'
		ns=[100;220;470];
	case 'E6'
		ns=[100;150;220;330;470;680];
	case 'E12'
		ns=[100;120;150;180;220;270;330;390;470;560;680;820];
	case 'E24'
		ns=[100;110;120;130;150;160;180;200;220;240;270;300;...
			330;360;390;430;470;510;560;620;680;750;820;910];
	case 'E48'
		ns=[100;105;110;115;121;127;133;140;147;154;162;169;...
			178;187;196;205;215;226;237;249;261;274;287;301;...
			316;332;348;365;383;402;422;442;464;487;511;536;...
			562;590;619;649;681;715;750;787;825;866;909;953];
	case 'E96'
		ns=[100;102;105;107;110;113;115;118;121;124;127;130;...
			133;137;140;143;147;150;154;158;162;165;169;174;...
			178;182;187;191;196;200;205;210;215;221;226;232;...
			237;243;249;255;261;267;274;280;287;294;301;309;...
			316;324;332;340;348;357;365;374;383;392;402;412;...
			422;432;442;453;464;475;487;499;511;523;536;549;...
			562;576;590;604;619;634;649;665;681;698;715;732;...
			750;768;787;806;825;845;866;887;909;931;953;976];
	case 'E192'
		ns=[100;101;102;104;105;106;107;109;110;111;113;114;...
			115;117;118;120;121;123;124;126;127;129;130;132;...
			133;135;137;138;140;142;143;145;147;149;150;152;...
			154;156;158;160;162;164;165;167;169;172;174;176;...
			178;180;182;184;187;189;191;193;196;198;200;203;...
			205;208;210;213;215;218;221;223;226;229;232;234;...
			237;240;243;246;249;252;255;258;261;264;267;271;...
			274;277;280;284;287;291;294;298;301;305;309;312;...
			316;320;324;328;332;336;340;344;348;352;357;361;...
			365;370;374;379;383;388;392;397;402;407;412;417;...
			422;427;432;437;442;448;453;459;464;470;475;481;...
			487;493;499;505;511;517;523;530;536;542;549;556;...
			562;569;576;583;590;597;604;612;619;626;634;642;...
			649;657;665;673;681;690;698;706;715;723;732;741;...
			750;759;768;777;787;796;806;816;825;835;845;856;...
			866;876;887;898;909;920;931;942;953;965;976;988];
	otherwise
		error('SC:round63:ser:NotSupported',...
			'Series "%s" is not supported.',ser)
end
%
%%% Preallocate Output Arrays %%%
%
Y = nan(size(X));
idx = Y;
pns = [];
edg = [];
%
%%% Calculate Rounded Values %%%
%
pwr = log10(double(X(:)));
idr = isfinite(pwr)&imag(pwr)==0;
%
if ~any(idr)
	return
end
%
% Determine the order of PNS magnitude required:
omn = floor(min(pwr(idr)));
omx =  ceil(max(pwr(idr)));
% Extrapolate the PNS vector to cover all input values:
pns = ns*10.^(omn-3:omx-1);
pns = pns(:);
%
% Generate bin edge values:
nmc = numel(rnd);
if strncmpi(rnd,'harmonic',nmc) % simulates component tolerance limits.
	rnd = 'harmonic';
	edg = 2*pns(1:end-1).*pns(2:end)./(pns(1:end-1)+pns(2:end));
elseif strncmpi(rnd,'arithmetic',nmc) % mid-point between PNS values.
	rnd = 'arithmetic';
	edg = (pns(1:end-1)+pns(2:end))./2;
elseif strncmpi(rnd,'up',nmc) || strncmpi(rnd,'ceiling',nmc)
	rnd = 'up';
	edg = pns(1:end-1);
elseif strncmpi(rnd,'down',nmc) || strncmpi(rnd,'floor',nmc)
	rnd = 'down';
	edg = pns(2:end);
else
	error('SC:round63:rnd:NotSupported',...
		'Rounding method "%s" is not supported.',rnd)
end
%
lwb = pow2(log2(realmin())/2);
idf = edg>lwb & isfinite(edg);
edg = edg(idf);
idf(1+find(idf,1,'last')) = true;
pns = pns(idf);
%
if numel(edg)<2
	return
end
%
% Place values of X into PNS bins:
if strncmpi(rnd,'up',nmc)
	[~,bin] = histc(-X(idr),-edg(end:-1:1));
	bin = numel(pns)-bin-1;
else
	[~,bin] = histc(X(idr),edg);
end
%
idb = bin>0;
idr(idr) = idb;
bin = bin(idb);
%
% Use the bin indices to select output values from the PNS:
Y(idr) = pns(1+bin);
%
% Remove superfluous PNS and bin edge values from vectors:
pns = pns(1+min(bin):1+max(bin));
edg = edg(0+min(bin):1+max(bin));
idx(idr) = 1+bin-min(bin);
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%round63
function arr = rst1s2c(arr)
% If scalar string then extract the character vector, otherwise data is unchanged.
if isa(arr,'string') && isscalar(arr)
	arr = arr{1};
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%rst1s2c