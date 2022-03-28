
angleRad = linspace(0,(4/5)*2*pi,5)';
X = sin(angleRad);
Y = cos(angleRad);
V = [X,Y];
A = [0,0,1,1,0;...
     0,0,0,1,1;...
     1,0,0,0,1;...
     1,1,0,0,0;...
     0,1,1,0,0];

kmlStr = ge_gplot(A,V,'lineWidth',5.0,...
                      'lineColor','FF00FF00',...
                      'altitudeMode','relativeToGround',...
                      'altitude',1e6,...
                      'msgToScreen',true,...
                      'extrude',1);
                                                                                                                
ge_output('example_ge_gplot.kml',kmlStr);
                            