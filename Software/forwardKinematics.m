% forwardKinematics.m
function [fx, fy, fz] = forwardKinematics(theta, link_lengths)
    % forwardKinematics.m
    % Computes the positions of each joint and the end-effector based on joint angles and link lengths.
    %
    % Inputs:
    %   theta - [4x1] Joint angles [theta1; theta2; theta3; theta4] in radians
    %   link_lengths - [1x4] Link lengths [a1, a2, a3, a4] in meters
    %
    % Outputs:
    %   fx, fy, fz - [1x5] Positions of base, joint1, joint2, joint3, end-effector

    % Extract link lengths
    a1 = link_lengths(1);
    a2 = link_lengths(2);
    a3 = link_lengths(3);
    a4 = link_lengths(4);

    % Extract joint angles
    theta1 = theta(1);
    theta2 = theta(2);
    theta3 = theta(3);
    theta4 = theta(4);

    % Compute cumulative angles
    theta12 = theta1 + theta2;
    theta123 = theta12 + theta3;
    theta1234 = theta123 + theta4;

    % Base position
    fx(1) = 0;
    fy(1) = 0;
    fz(1) = 0;

    % Joint 1 position
    fx(2) = 0;
    fy(2) = 0;
    fz(2) = a1;

    % Joint 2 position
    fx(3) = fx(2) + cos(theta1) * a2 * cos(theta2);
    fy(3) = fy(2) + sin(theta1) * a2 * cos(theta2);
    fz(3) = fz(2) + a2 * sin(theta2);

    % Joint 3 position
    fx(4) = fx(3) + cos(theta1) * a3 * cos(theta2 + theta3);
    fy(4) = fy(3) + sin(theta1) * a3 * cos(theta2 + theta3);
    fz(4) = fz(3) + a3 * sin(theta2 + theta3);

    % End-effector position
    fx(5) = fx(4) + cos(theta1) * a4 * cos(theta2 + theta3 + theta4);
    fy(5) = fy(4) + sin(theta1) * a4 * cos(theta2 + theta3 + theta4);
    fz(5) = fz(4) + a4 * sin(theta2 + theta3 + theta4);
end
