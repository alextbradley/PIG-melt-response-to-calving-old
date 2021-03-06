%Make figure 6 in the PIG calving manuscript: plots of (a) mean melt rate with calving and (b) decomposition of changes in melting for W = 100, 150, 200
%
% NB: Many of the data files referred to in this script are too large to be hosted online. These files are hosted internally as BAS.
% Please email Alex Bradley (aleey@bas.ac.uk) to obtain a copy. 

%Alex Bradley (aleey@bas.ac.uk) 27/05/2021. MIT license.

%
% Flags
%
gendata = 0; %specify whether to pass through the generate data loop
save_flag = 0; 

%
% Preliminaries
%
addpath("plot_tools");
plot_defaults
label_size = 11;
ax_fontsize = 10;
figure(1); clf; 
fig = gcf; fig.Position(3:4) = [1000, 390];

%
% Data locations
rootdir = '/data/oceans_output/shelf/aleey/mitgcm/APIGi_'; %not in git repo
topodir = '../gendata/topo_files/';
bathy_path = '../gendata/bathy_files/bathymetry_H400.shice';

%grid details
nx=120; % number of grid cells along longitudinal direction
ny=320; % number of grid cells along latitudinal direction
nz=110; % number of vertical grid cells
dx=400;
dy=400;
dz=10;
X = 0:dx:(nx-1)*dx;
Y = 0:dx:(ny-1)*dy;
Z = 0:dz:(nz-1)*dz;
[XX,YY] = meshgrid(X,Y);
YYt = YY';
idx = (YYt < 30e3); %inner cavity definition

%parameters
secs_per_year = 365.25*24*60*60;
density_ice = 918.0;
lambda = 7.61*1e-4;%constants in liquidus
gamma = 5.73*1e-2;
T0 = 8.32*1e-2;



%time details
ntout1 = 6; 
ntout2 = 8; %define time period to average over

% 
% Generate data loop
%
run_nos =["077", "078", "079", "080", "081", "082", "083", "084", "085", "086"; %H = 100
	"102", "102", "103", "104", "105", "106", "107", "108", "109", "110"; %H = 150
	"125", "126", "127", "128", "129", "130", "131", "132", "133", "134"]; %H = 200
sz = size(run_nos);
extent = [84,80,75,70,65,60,55,50,45,40];
H = 400; %ridge height (always 400);
W = [100,150, 200]; %ridge gap

%generate data loop
if gendata

%load unchanging bathy
fid = fopen(bathy_path);
bathy = fread(fid, 'real*8', 'b');
bathy = reshape(bathy, [nx, ny]);
bathy(bathy == 0) = nan;

%setup storage
melt_scenarios = cell(sz);
Ubl_scenarios  = cell(sz);
Vbl_scenarios  = cell(sz);
Tbl_scenarios  = cell(sz);
Sbl_scenarios  = cell(sz);
topo_scenarios = cell(sz); 

%loop over runs
for i = 1:sz(1)
for j = 1:sz(2)
%draft
topo_fname=  ['shelfice_topo_H' num2str(H) '_W' num2str(W(i)) '_extent' num2str(extent(j)) 'km.bin'];
topo_fid = fopen(strcat(topodir, '/',topo_fname));
topo = fread(topo_fid, 'real*8', 'b');
topo = reshape(topo, [nx, ny]);
topo_scenarios{i,j} = topo;

%melt rates
state2D_fname = strcat(rootdir, run_nos(i,j), '/run/state2D.nc');
melt = ncread(state2D_fname, 'SHIfwFlx', [1, 1, ntout1], [Inf, Inf, 1+ntout2- ntout1]);
melt = mean(melt, 3); %average over months ntout1 to ntout2
melt = -melt * secs_per_year / density_ice;
melt_scenarios{i,j} = melt;

%Theta
Theta_fname = strcat(rootdir, run_nos(i,j), '/run/stateTheta.nc');
Theta = ncread(Theta_fname, 'THETA', [1,1,1,ntout1], [Inf, Inf, Inf, 1+ntout2 - ntout1]);
Theta = mean(Theta, 4);

%Salinity
Salt_fname = strcat(rootdir, run_nos(i,j), '/run/stateSalt.nc');
Salt = ncread(Salt_fname, 'SALT', [1,1,1,ntout1], [Inf, Inf, Inf, 1+ntout2 - ntout1]);
Salt = mean(Salt, 4);

%Velocities
UVEL_fname = strcat(rootdir, run_nos(i,j), '/run/stateUvel.nc');
UVEL = ncread(UVEL_fname, 'UVEL', [1,1,1,ntout1], [Inf, Inf, Inf,  1+ntout2 - ntout1]);
UVEL = mean(UVEL, 4);
VVEL_fname = strcat(rootdir, run_nos(i,j), '/run/stateVvel.nc');
VVEL = ncread(VVEL_fname, 'VVEL', [1,1,1,ntout1], [Inf, Inf, Inf,  1+ntout2 - ntout1]);
VVEL = mean(VVEL, 4);

%boundary layer quantities
Nb = 3; %number of grid pts to take mean over
Sbl = nan(nx,ny); Tbl = nan(nx,ny); Ubl = nan(nx, ny); Vbl = nan(nx,ny);
for p = 1:nx
for q = 1:ny
        if topo(p, q) < 0 %if we're in the cavity
                idxtop = find((topo(p,q) - (-Z)) > 0, 1, 'first'); %gives you the index of first Z grid point above the bathymetry
                idxtop = find(Theta(p,q,:) ~= 0);
                idxtop = idxtop(1);
                Sbl(p,q) = double(mean(Salt(p,q,idxtop:idxtop+Nb-1)));
                Tbl(p,q) = double(mean(Theta(p,q,idxtop:idxtop+Nb-1)));
                Ubl(p,q) = double(mean(UVEL(p,q,idxtop:idxtop+Nb-1)));
                Vbl(p,q) = double(mean(VVEL(p,q,idxtop:idxtop+Nb-1)));
	
		if 1 %account for partial cell in the mean calculation
		draft = topo(p,q);
		partial_cell_frac = abs(rem(draft, dz)) / dz;
		draft_rounded = draft + abs(rem(draft, dz)); 
		[~,idxtop] = min(abs(-Z - draft_rounded));
		vec = [partial_cell_frac,1,1]';
		Sbl(p,q) = sum(vec.*squeeze(Salt(p,q,idxtop:idxtop+Nb-1)))/sum(vec);
		Tbl(p,q) = sum(vec.*squeeze(Theta(p,q,idxtop:idxtop+Nb-1)))/sum(vec);
		
		Ubl(p,q) = sum(vec.*squeeze(UVEL(p,q,idxtop:idxtop+Nb-1)))/sum(vec);
		Vbl(p,q) = sum(vec.*squeeze(VVEL(p,q,idxtop:idxtop+Nb-1)))/sum(vec);
		end
		
        end
end %end loop over y grid
end %end loop over x grid

Sbl_scenarios{i,j} = Sbl;
Tbl_scenarios{i,j} = Tbl;
Ubl_scenarios{i,j} = Ubl;
Vbl_scenarios{i,j} = Vbl;


end %end loop over i
end %end loop over j
end %end generate data loop

%
% Plots
%

positions = [0.1,0.1,0.4,0.85;
	     0.6, 0.55, 0.38, 0.4;
	     0.6, 0.1, 0.38, 0.4];

%
% Plot 1: Mean inner cavity melt rate with calving
%
subplot('Position', positions(1,:));
grid on; hold on; ax = gca; box on

for i = 1:3
ave_melt = zeros(1,sz(2));
for j = 1:sz(2)
melt = cell2mat(melt_scenarios(i,j));
ave_melt(j) = mean(melt(idx));
end

plot([34,34],  [45,75], 'k--', 'linewidth', 1.5, 'HandleVisibility', 'off'); %plot the location of top of ridge
if i == 1 %H =  100
plot(84 - extent, ave_melt, 'o-', 'color', 0.6*ones(3,1), 'markerfacecolor', 0.6*ones(3,1));
elseif i == 2
plot(84 - extent, ave_melt, 'o-', 'color', plotcolor1, 'markerfacecolor', plotcolor1);
elseif i == 3
plot(84 - extent, ave_melt, 'o-', 'color', plotcolor2, 'markerfacecolor', plotcolor2);
end %end plot style by H value
end %end loop over i

xlabel('$l_c$ (km)', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('Inner cavity melt rate (m/yr)', 'Interpreter', 'latex', 'FontSize', 12);
xlim([0, 45]);
ylim([45,75])
legend({"$W$ = 100~m", "$W$ = 150~m", "$W$ = 200~m"}, 'location', 'southeast', 'FontSize', 12, 'Interpreter', 'latex');
text(-10,75, "(a)", 'Interpreter', 'latex', 'FontSize', 12)

%
% Decompositions for H = 150, 200
%

for i = 2:3
subplot('Position', positions(i,:))
grid on; hold on; ax = gca; box on

%set up storage
relmelt        = zeros(1,sz(2));
relmelt_noTemp = zeros(1,sz(2));
relmelt_noVel  = zeros(1,sz(2));

%get the baseline velocity, theta, salt
Ubl_baseline = cell2mat(Ubl_scenarios(i,1));
Vbl_baseline = cell2mat(Vbl_scenarios(i,1));
Tbl_baseline = cell2mat(Tbl_scenarios(i,1));
Sbl_baseline = cell2mat(Sbl_scenarios(i,1));
Tl_baseline  = T0 + lambda*topo - gamma*Sbl_baseline;
UdT_baseline = sqrt(Ubl_baseline.^2 + Vbl_baseline.^2) .* (Tbl_baseline - Tl_baseline);
for j = 1:sz(2)

%get the current velocity, theta, salt
Ubl = cell2mat(Ubl_scenarios(i,j));
Vbl = cell2mat(Vbl_scenarios(i,i));
Tbl = cell2mat(Tbl_scenarios(i,j));
Sbl = cell2mat(Sbl_scenarios(i,j));
Tl  = T0 + lambda*topo - gamma*Sbl; %liquidus temperature in BL

%compute relative melt contributions
UdT = sqrt(Ubl.^2 + Vbl.^2) .* (Tbl - Tl);
UdT_noVel =  sqrt(Ubl_baseline.^2 + Vbl_baseline.^2) .* (Tbl - Tl);
UdT_noTemp = sqrt(Ubl.^2 + Vbl.^2) .* (Tbl_baseline - Tl_baseline);

relmelt(j) = nanmean(UdT(idx)) / nanmean(UdT_baseline(idx)); 
relmelt_noTemp(j) = nanmean(UdT_noTemp(idx)) / nanmean(UdT_baseline(idx));
relmelt_noVel(j) = nanmean(UdT_noVel(idx)) / nanmean(UdT_baseline(idx));

end %end loop over runs
plot([34,34],  [0.6, 1.4], 'k--', 'linewidth', 1.5, 'handlevisibility', 'off'); %plot the location of top of ridge
plot(84 - extent, relmelt, 'o-', 'color', plotcolor1, 'markerfacecolor', plotcolor1);
plot(84 - extent, relmelt_noTemp, 'o-', 'color', plotcolor2, 'markerfacecolor', plotcolor2);
plot(84 - extent, relmelt_noVel, 'o-', 'color', plotcolor3, 'markerfacecolor', plotcolor3);

%tidy plots
xlim([0, 45])
ylabel('Relative change', 'Interpreter', 'latex', 'FontSize', 12);
if i == 3

txt200= text(0.1, 1.175,"$W = 200$~m", 'interpreter', 'latex', 'FontSize', 12) ;
ylim([0.8, 1.2])
legend({"$\mathcal{M}$", "$U_e$", "$\Delta T_e$"}, 'location', 'southwest','interpreter', 'latex', 'FontSize', 12)
text(-10,1.2, "(c)", 'Interpreter', 'latex', 'FontSize', 12)
xlabel('$l_c$ (km)', 'Interpreter', 'latex', 'FontSize', 12);

else
txt150 = text(0.1, 1.35,"$W = 150$~m", 'interpreter', 'latex', 'FontSize', 12) ;
ax = gca; ax.XTickLabels = cell(0,1);
ylim([0.6, 1.4])
text(-10,1.4, "(b)", 'Interpreter', 'latex', 'FontSize', 12)

end
end

%
% Save figure
%
if save_flag
%saveas(gcf, "plots/figure6", 'epsc')
saveas(gcf, "plots/figure6.png")
end

