color_mtx = zeros(63,3);
color_mtx (1:31,3)  = 1;
color_mtx (33:63,3)  = linspace(1,0,31);

color_mtx (1:31,1)  = linspace(0,1,31);
color_mtx (33:63,1)  = 1;
color_mtx(32,:) = [1 1 1];
color_mtx (33:63,2)  = linspace(1,0,31);
color_mtx (1:31,2)  = linspace(0,1,31);

colormap(gca, color_mtx)