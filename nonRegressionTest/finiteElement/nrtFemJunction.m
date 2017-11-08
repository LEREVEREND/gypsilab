%+========================================================================+
%|                                                                        |
%|            This script uses the GYPSILAB toolbox for Matlab            |
%|                                                                        |
%| COPYRIGHT : Matthieu Aussal & Francois Alouges (c) 2015-2017.          |
%| PROPERTY  : Centre de Mathematiques Appliquees, Ecole polytechnique,   |
%| route de Saclay, 91128 Palaiseau, France. All rights reserved.         |
%| LICENCE   : This program is free software, distributed in the hope that|
%| it will be useful, but WITHOUT ANY WARRANTY. Natively, you can use,    |
%| redistribute and/or modify it under the terms of the GNU General Public|
%| License, as published by the Free Software Foundation (version 3 or    |
%| later,  http://www.gnu.org/licenses). For private use, dual licencing  |
%| is available, please contact us to activate a "pay for remove" option. |
%| CONTACT   : matthieu.aussal@polytechnique.edu                          |
%|             francois.alouges@polytechnique.edu                         |
%| WEBSITE   : www.cmap.polytechnique.fr/~aussal/gypsilab                 |
%|                                                                        |
%| Please acknowledge the gypsilab toolbox in programs or publications in |
%| which you use it.                                                      |
%|________________________________________________________________________|
%|   '&`   |                                                              |
%|    #    |   FILE       : nrtFemJunction.m                              |
%|    #    |   VERSION    : 0.30                                          |
%|   _#_   |   AUTHOR(S)  : Matthieu Aussal                               |
%|  ( # )  |   CREATION   : 14.03.2017                                    |
%|  / 0 \  |   LAST MODIF : 05.09.2017                                    |
%| ( === ) |   SYNOPSIS   : Junction beetween domains (linear relation)   |
%|  `---'  |                                                              |
%+========================================================================+

% Cleaning
clear all
close all
clc

% Library path
addpath('../../openDom')
addpath('../../openFem')
addpath('../../openMsh')

% Parameters
Nvtx = 1e3;
Neig = 10;

% Horizontal mesh
mesh1                 = mshSquare(Nvtx,[1,1]);
ctr                   = mesh1.ctr;
mesh1.col(ctr(:,1)<0) = 1;
mesh1.col(ctr(:,1)>0) = 2;

% Vertical mesh
mesh2          = mshSquare(Nvtx/2,[0.5 1]);
mesh2.col(:)   = 3;
mesh2.vtx(:,3) = 0.25+mesh2.vtx(:,1);
mesh2.vtx(:,1) = 0;

% Final mesh
mesh = union(mesh1,mesh2);

% Boundary
bound = mesh.bnd;

% Domain
omega = dom(mesh,3);
sigma = dom(bound,2);

% Finites elements space
u = fem(mesh,'P1');
v = fem(mesh,'P1');

% Dirichlet
u = dirichlet(u,bound);
v = dirichlet(v,bound);

% Junctions
u = junction(u,[1 2 3],[1 1 1]);
v = junction(v,[1 2 3],[1 1 1]);

% Graphical representation
plot(mesh); 
hold on
plot(bound,'r')
hold off
axis equal;
title('Mesh representation')
xlabel('X');   ylabel('Y');   zlabel('Z');

% Mass matrix
tic
M = integral(omega,u,v);
toc

% Rigidity matrix
tic
K = integral(omega,grad(u),grad(v));
toc

% Find eigen values
tic
[V,EV] = eigs(K,M,2*Neig,'SM');
toc

% Normalization
V = V./(max(max(abs(V))));

% Sort by ascending order
[EV,ind] = sort(sqrt(real(diag(EV))));
V        = V(:,ind);

% Separated meshes
mesh1 = mesh.sub(mesh.col==1);
mesh2 = mesh.sub(mesh.col==2);
mesh3 = mesh.sub(mesh.col==3);

% Final valueas
[X,P] = u.unk;
V     = P * V;
V1    = V(1:size(mesh1.vtx,1),:);    
V2    = V(size(V1,1)+(1:size(mesh2.vtx,1)),:);    
V3    = V(size(V1,1)+size(V2,1)+1:end,:);

% Graphical representation
figure
for n = 1:9
    subplot(3,3,n)
    hold on
    plot(mesh1,V1(:,n))
    plot(mesh2,V2(:,n))
    plot(mesh3,V3(:,n))
    axis equal off
    colorbar
end

% Analytical solutions of eigenvalues for an arbitrary cube
ref = zeros(Neig^2,1);
L   = [1 1];
l = 1;
for i = 1:Neig
    for j = 1:Neig
        ref(l) = pi*sqrt( (i/L(1))^2 + (j/L(2))^2 );
        l = l+1;
    end
end
ref = sort(ref);
ref = ref(1:Neig);

% Error
sol = EV(1:Neig);
[ref sol]


disp('~~> Michto gypsilab !')


