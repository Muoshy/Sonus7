function [eqv,cmp,idx,pns] = num2circuit(X,ser,bnd,nmc,isr)
% Select parallel/series component values that best match the input value.
%
% (c) 2014-2021 Stephen Cobeldick
%
% NUM2CIRCUIT uses an exhaustive search to find the electronic component
% values which can be used in a parallel or series circuit whose equivalent
% circuit value is the closest match to the value of each input matrix element.
%
%%% Syntax:
% eqv = num2circuit(X,ser,bnd,nmc,isr)
% [eqv,cmp,idx,pns] = num2circuit(...)
%
% Output <cmp> contains component values from an IEC 60063 E-series of
% values, such that equivalent circuit value <eqv> is the closest possible
% to the value of input <X>.
%
% The input <ser> selects the component series (defined by IEC 60063): E3,
% E6, E12, E24, E48, E96, or E192. The component value range is specified
% by input <bnd>, while the number of components in the circuit is selected
% using the input <nmc>. Input <isr> selects either a non-reciprocal or a
% reciprocal for the equivelent circuit (see "Series or Parallel Circuit").
%
% Note1: A large range + many components + high E-series = very slow!
% Note2: Requires M-file ROUND63, available on MATLAB's File Exchange.
%
%% Series or Parallel Circuit %%
%
% Different circuits require different summation methods. Use the table
% below to look up what kind of circuit you need (e.g. parallel resistors),
% and then pick the appropriate logical value for the input <isr>:
%
% <isr>  | Sum of component  | For series circuit of  | For parallel circuit of
% -------|-------------------|------------------------|------------------------
% true   | value reciprocals | capacitors             | resistors or inductors
% -------|-------------------|------------------------|------------------------
% false  | values            | resistors or inductors | capacitors
% -------|-------------------|------------------------|------------------------
%
%% Examples %%
%
% >> [eqv,cmp] = num2circuit(123, 'E6', [5,5000], 3, true)
% eqv =
%        123.13
% cmp =
%         2200         150        1000
%
% >> [eqv,cmp] = num2circuit([19; 10; 1982], 'E24', [1,1000], 4, false)
% eqv =
%           19
%           10
%         1982
% cmp = 
%            1            1            1           16
%            1            1          1.2          6.8
%            2          160          820         1000
%
% >> [eqv,cmp] = num2circuit([0.8; 8; 88; 888; Inf], 'E6', [1,5000], 2, true)
% eqv =
%       0.82456
%        8.2456
%        87.179
%        891.89
%           NaN
% cmp =
%           4.7            1
%            47           10
%           680          100
%          2200         1500
%           NaN          NaN
%
% >> [eqv,cmp,idx,pns] = num2circuit(12345, 'E12', [10,20000], 3, false)
% eqv = 12345
% cmp = [12000, 330, 15]
% idx = [   38,  19,  3]
% pns = [10; 12; 15; 18; 22; 27; 33; 39; 47;...12000; 15000; 18000]
%
%% Input and Output Arguments %%
%
% The rows of outputs <val>, <eqv> and <idx> are linear indexed relative to
% input <X>. Outputs <val> and <idx> have <nmc> columns.
%
%%% Inputs:
%  X   = Numeric matrix, values to match using an equivalent circuit.
%  ser = String/char to select component E-series: see the ROUND63 M-file.
%  bnd = Numeric Vector, two elements: [Min,Max] permitted component values.
%  nmc = Numeric scalar, select the number of components in the circuit.
%  isr = Logical scalar, true/false -> sum value reciprocals / sum values.
%
%%% Outputs (all are numeric, input Inf & NaN values are returned as NaN):
%  eqv = Matrix, equivalent circuit value using the components in <cmp>.
%  cmp = Matrix, component values that sum to best match values of <X>.
%  idx = Matrix, index showing which <pns> component values were returned.
%  pns = Vector, the component series, all contiguous values within <bnd>.
%
% See also ROUND63 NUM2SIP NUM2BIP SIP2NUM BIP2NUM ROUND HISTC HISTCOUNTS

assert(isnumeric(X),'First input <X> must be a numeric scalar, vector or matrix.')
assert(isreal(X),'First input <X> must contain real numeric values only.')
assert(isnumeric(bnd)&&numel(bnd)==2,'Third input <bnd> must a two element numeric.')
assert(isnumeric(nmc)&&isscalar(nmc),'Fourth input <nmc> must be numeric scalar.')
assert(islogical(isr)&&isscalar(isr),'Fifth input <isr> must be a logical scalar.')
%
X = X(:);
nmx = numel(X);
%
% Location of finite values in matrices <X> and <val>:
oki = isfinite(X) & X>0;
oko = reshape(repmat(oki,1,nmc),[],1);
% Preallocate equivalent circuit, component value and PNS index matrices:
eqv = NaN(nmx,1);
cmp = NaN(nmx,nmc);
idx = NaN(nmx,nmc);
%
% Get vector of PNS values:
[~,~,pns] = round63(bnd,ser);
pns = pns(pns>=bnd(1) & pns<=bnd(2));
%
if nmx<1 || nmc<1
	return
end
%
nmv = numel(pns);
cev = n2cReciprocal(isr,pns(:));
%
% Maximum number of elements (adjust to suit OS & computer):
mxe = pow2(22);
%
if mxe<nmv^nmc% Method: iterate over all PNS multiset indices, each step
	% comparing the sum of each multiset. (Slow, but no large matrices)
	%
	% Initial values:
	cpr = Inf(nmx,1);% Previous best (aim = -Inf).
	idm = ones(1,nmc);% First multiset index.
	idx(oko) = 1;%  First multiset indices.
	eqv(oki) = n2cReciprocal(isr,sum(cev(idm)));% Value at first index.
	%
	for p = 2:prod(nmv:(nmv+nmc-1))/prod(1:nmc)
		%
		% Determine the next unique multiset index:
		if idm(nmc)==nmv
			cnt = nmc-1;
			while idm(cnt)==nmv
				cnt = cnt-1;
			end
			idm(cnt:nmc) = 1+idm(cnt);
		else
			idm(nmc) = 1+idm(nmc);
		end
		%
		% Sum value to compare previous best with:
		vat = n2cReciprocal(isr,sum(cev(idm)));
		cpt = log(abs(X-vat));
		% If the sum is closer, then replace previous best and multiset indices:
		q = cpt<cpr;
		cpr(q) = cpt(q);
		eqv(q) = vat;
		for k = find(q).'
			idx(k,:) = idm;
		end
		%
	end
	%
else% Method: Generate complete PNS-sum multiset matrix in one go, and
	% compare all possible sums at once. (Fast, but uses large matrices)
	%
	sza = nmv*ones(1,nmc);
	arr = repmat(cev,[1,sza(2:end)]);% Large!
	%
	% Cumulative sums of all the PNS values, for all multisets:
	for m = 2:nmc
		cev = shiftdim(cev,-1);
		arr = bsxfun(@plus,arr,cev);
	end
	arr = n2cReciprocal(isr,arr(:));
	%
	% Best matches of input values to equivalent circuits (sums):
	[~,idm] = min(log(abs(bsxfun(@minus,X.',arr))),[],1);
	%
	% Return equivalent values and component indices:
	for k = find(oki).'
		eqv(k) = arr(idm(k));
		idx(k,:) = n2cInd2Sub(sza,idm(k));
	end
	%
end
%
cmp(oko) = pns(idx(oko));
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%num2circuit
function val = n2cReciprocal(isr,val)
if isr
	val = 1./val;
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%n2cReciprocal
function sub = n2cInd2Sub(sza,idx)
% Subscript index vector from matrix size and linear index.
sub = sza;
cum = [1,cumprod(sza(1:end-1))];
for k = numel(sza):-1:1
	tmp = 1+rem(idx-1,cum(k));
	sub(k) = 1+(idx-tmp)/cum(k);
	idx = tmp;
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%n2cInd2Sub