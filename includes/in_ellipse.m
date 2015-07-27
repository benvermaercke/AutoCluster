function out=in_ellipse(x,y,a,b,xc,yc,t)
%%% Checks whether points (x,y) lie inside ellipse defined by axis lengths
%%% (a,b), center position (xc,yc) and angle (t)
out = ((x-xc)*cos(t)-(y-yc)*sin(t)).^2/a^2 + ((x-xc)*sin(t)+(y-yc)*cos(t)).^2/b^2 <= 1;