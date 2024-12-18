clc; clear all;

syms theta1 theta2 theta3 theta4 real
% syms d1 d2 real
d1=4;
a2=15;
a3=15;
a4=15;
% DH parameters
test_dh = [0  0 d1 theta1; ...
           0 pi/2 0 theta2; ...
           a2 0 0 theta3; ...
           a3 0 0 theta4; ...
           a4 0 0 0; ...
           ]
% Parameter ranges
points=40;
theta1_range = linspace(0,2*pi, points);
 theta2_range = linspace(0,pi/2, points);
 theta3_range = linspace(0,pi/2, points);
 theta4_range = linspace(0,pi/3, points);
% d1_range = linspace(6,7, 180);
% d2_range = linspace(4,5,180);
test_map = containers.Map({'theta1','theta2','theta3','theta4'},{theta1_range,theta2_range,theta3_range,theta4_range, });

% Workspace plotting function
plot3dworkspace(test_dh, test_map);%, @get_alternative_dh_transform)


function out = arr2Rad(A)
    out = arrayfun(@(angle) deg2rad(angle), A);
end

function T = get_alternative_dh_transform(a,alpha,d,theta)
T = [cos(theta) -cos(alpha)*sin(theta) sin(alpha)*sin(theta) a*cos(theta)
     sin(theta) cos(alpha)*cos(theta) -sin(alpha)*sin(theta) a*sin(theta)
     0 sin(alpha) cos(alpha) d
     0 0 0 1];
end