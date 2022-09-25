function round63_view(X,ser,varargin)
% Create a figure that compares E-series tolerances with ROUND63 bin edges.
%
% (c) 2014-2021 Stephen Cobeldick
%
% Creates a figure to illustrate how ROUND63's rounding bin edges match
% the component tolerances, depending on the selected rounding method.
%
%%% Syntax:
%  round63_view(X,ser)
%  round63_view(X,ser,rnd)
%
%% Examples %%
%
% >> round63_view([2,5],'E12')
%
% >> round63_view([1,11],'E6') % default = 'harmonic'
% >> round63_view([1,11],'E6','up')
% >> round63_view([1,11],'E6','down')
% >> round63_view([1,11],'E6','arithmetic')
%
%% Input Arguments %%
%
%%% Inputs:
%  X   = Numeric, some values to plot and view the rounding edges for.
%  ser = String, to select the E-Series. See ROUND63 for a full list.
%
% See also ROUND63 ROUND63_TEST NUM2CIRCUIT NUM2SIP NUM2RKM ROUND HISTC HISTCOUNTS

persistent fgh axh
%
% Get PNS and edge values:
[~,idx,pns,edg,rnd] = round63(X,ser,varargin{:});
assert(numel(pns)>1,'Increase the input value range (it must cover multiple E-series values)')
% Estimate tolerance (valid from E3 to E192):
tol = mean((pns(2:end)-pns(1:end-1))./(pns(2:end)+pns(1:end-1)));
coe = 10^-floor(log10(tol));
tol = round(10^(round(3*log10(tol*coe))/3))/coe; % round to [1,2,5] series
%
% Re-use figure or create new figure:
if ishghandle(fgh)
	cla(axh);
else
	fgh = figure('NumberTitle','off','Name','ROUND63 Demonstration',...
		'HandleVisibility','callback','MenuBar','figure', 'Toolbar','none');
	axh = axes('Parent',fgh);
end
%
% Plot edges, PNS values, and tolerances:
idy = 1:numel(pns);
idz = [0,1+idy(end)];
ln1 = plot(axh,[edg,edg],idz,'g-');
hold(axh,'on')
ln2 = plot(axh,pns,idy,'db');
ln3 = plot(axh,[pns.'*(1-tol);pns.'*(1+tol)],[idy;idy],'or-');
ln4 = plot(axh,X(:),idx(:),'+k');
%
% Add labels and legend:
set(axh, 'YLim',idz, 'YTick',idy, 'YTickLabel',pns)
xlabel(axh,'Input Values (pre-rounding)')
ylabel(axh,['Output Values (',ser,' Component Values)'])
legend(axh,[ln1(1),ln2(1),ln3(1),ln4(1)],'ROUND63 bin edges','Nominal component value',...
	sprintf('Component tolerance (%.9g%%)',100*tol),'Input numeric values','Location','SouthEast')
title(axh,sprintf('Component Tolerance and Bin Edge Comparison (%s)',lower(rnd)))
%
drawnow()
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%round63_view