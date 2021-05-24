%Make figure 2 in the manuscript: schematic of the shelf geometry and hydrographic conditions
%Alex Bradley (aleey@bas.ac.uk), 21/05/2021

%
% Flags
% 
save_flag = 1; 



%
% Preliminaries
%
addpath("plot_tools");
plot_defaults
fig = figure(1); clf; 
fig.Position(3:4) = [900, 420];
label_size = 11;
ax_fontsize = 10;
%
% schematic of ice shelf geometry
%
yy = 0:400:(319*400);
yyf = max(yy) - yy;
[~, idx] = min(abs(yy - 84*1e3));
H = [100, 150, 200];
linestyles = ["-","--", "--"];
h_profiles = zeros(3, length(yy));
for i = 1:3
h_profiles(i,:)=(310 + H(i))/2.64*atan(0.17*yy/1000 - 3) + 0.47*(H(i)+400) - 1051.3;
h_profiles(i, idx+1:end) = nan;
end

pos = [0.1, 0.12, 0.5, 0.82];
p0 = subplot('Position', pos); box on; hold on
for i = 1:3
if i == 1
fillX = [yyf(1:idx), flip(yyf(1:idx))]/1e3;
fillY = [h_profiles(i,1:idx), zeros(1,idx)];
fill(fillX, fillY, [173, 216, 230]/255, 'linewidth', 1.5)

%add calving lines before other H values
lc = [103, 124, 200]/255; 
extent = 40:5:80;
for i = 1:9
	%find the value of H here
	[~,idx] = min(abs(yy - 1e3*extent(i)));
	hmin = h_profiles(length(yy) - idx);
	plot((128 - extent(i))*ones(1,2), [h_profiles(1,idx), 0], 'color', lc)
end

else
plot((max(yy) - yy)/1e3, h_profiles(i,:), 'k', 'linestyle', linestyles(i))
end
end

%add the ridge
fillX = [yy, flip(yy)]/1e3;
latg = [1.62e6:400:1.748e6-400];
bump = 400*exp(-(latg-1.67e6).^2/(2*12000^2)) - 1095;
fillY = [-1100*ones(1,length(yy)), bump];
fill(fillX, fillY, [203, 150, 80]/255, 'Linewidth', 1.5)
%plot(yyf/1e3, bump, 'k', 'linewidth', 1.5)	


xlabel('Y (km)')
ylabel('depth(m)')
xlim([min(yy), max(yy)]/1e3)
ylim([-1100, 0])
p0.YTick = [-1100,-1000:200:0];
p0.YLabel.String = 'depth (m)';
grid on

%add north south text
north = text(6,-210, "North", 'FontSize', 16);
set(north, 'Rotation', 90)

south = text(123,-210, "South", 'FontSize', 16);
set(south, 'Rotation', 90)

%add the H values
text(25,-480, "H = 200", 'FontSize', 11)
text(25,-580, "H = 100", 'FontSize', 11)
text(25,-530, "H = 150", 'FontSize', 11)

%
% salinity and temperature profiles
%
pos_t = [0.62, 0.12, 0.17, 0.82];
pos_s = [0.80, 0.12, 0.17, 0.82];
p1 = subplot('Position',pos_t); box on; hold on; grid on
p2 = subplot('Position',pos_s); box on; hold on; grid on
depth = 0:10:1110;

P = [600, 700. 800];
linestyles = ["-", "--", "--"];
for i = 1:3
[t_prof, s_prof] = TS_profile(depth,-1100,P(i) - 600, P(i)-600); %send and third arguments are offset from 600

plot(p1, t_prof,-depth(1:end-1), 'r', 'linestyle', linestyles(i), 'linewidth', 1.5);
plot(p2,s_prof, -depth(1:end-1), 'b', 'linestyle', linestyles(i), 'linewidth', 1.5);

end

%tidy up
p1.XLim = [-1.2, 1.4]; 
p1.YLim = [-1100,0];
p1.YLabel.FontSize = label_size;
p1.XLabel.String = 'Pot. temp. (\circC)';
p1.XLabel.FontSize = label_size;
p1.YTick = [-1100,-1000:200:0];
p1.FontSize = ax_fontsize;
p1.YTickLabel = cell(length(p2.YTickLabel),1);

p2.YTick = p1.YTick;
p2.YLim = [-1100,0];
p2.XLim = [33.9, 34.8];
p2.XTick = [34, 34.3, 34.6];
p2.YTickLabel = cell(length(p2.YTickLabel),1);
p2.XLabel.String = 'Salinity (psu)';
p2.XLabel.FontSize = label_size;
p2.FontSize = ax_fontsize;

%
% save
%
if save_flag 
saveas(gcf, "plots/figure2", 'epsc')
end
